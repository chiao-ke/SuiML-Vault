import Arweave from 'arweave';
import { randomBytes, createCipheriv, createHash } from 'crypto';
import * as fs from 'fs';
import dns from 'dns';

// 設置 DNS 解析
dns.setDefaultResultOrder('ipv4first');
dns.setServers(['8.8.8.8', '8.8.4.4']); // Using Google's DNS servers

// Arweave 網絡配置
const MAINNET_CONFIG = {
    host: 'arweave.net',  // Arweave 主網
    port: 443,
    protocol: 'https',
    timeout: 60000,  // Increase timeout to 60 seconds
    logging: true    // Enable logging for debugging
};

// 初始化 Arweave (使用主網)
const arweave = Arweave.init(MAINNET_CONFIG);

/**
 * 計算數據的SHA-256哈希值
 * @param data 要計算哈希的數據
 * @returns 哈希值（十六進制字符串）
 */
function calculateHash(data: Buffer): string {
    return createHash('sha256').update(data).digest('hex');
}

/**
 * 加密模型文件
 * @param data 模型數據
 * @returns 加密後的數據和密鑰
 */
async function encryptData(data: Buffer): Promise<{encryptedData: Buffer; key: string}> {
    const key = randomBytes(32);
    const iv = randomBytes(16);
    
    const cipher = createCipheriv('aes-256-cbc', key, iv);
    const encryptedData = Buffer.concat([
        iv,
        cipher.update(data),
        cipher.final()
    ]);

    return {
        encryptedData,
        key: key.toString('hex')
    };
}

/**
 * 檢查網絡連接
 */
async function checkNetwork() {
    try {
        const networkInfo = await arweave.network.getInfo();
        console.log('網絡信息:', {
            network: MAINNET_CONFIG.host,
            height: networkInfo.height,
            current: networkInfo.current,
            release: networkInfo.release,
        });
    } catch (error) {
        console.error('網絡連接失敗:', error);
        process.exit(1);
    }
}

/**
 * 上傳模型到Arweave
 */
async function uploadModel() {
    try {
        // 首先檢查網絡連接
        await checkNetwork();

        // 讀取錢包
        const wallet = JSON.parse(fs.readFileSync('./model-upload/arweave-wallet.json', 'utf-8'));
        
        // 獲取錢包地址
        const address = await arweave.wallets.jwkToAddress(wallet);
        console.log('錢包地址:', address);

        // 檢查餘額
        const balance = await arweave.wallets.getBalance(address);
        const ar = arweave.ar.winstonToAr(balance);
        console.log('主網錢包餘額:', ar, 'AR');

        if (Number(ar) <= 0) {
            console.log('警告: 餘額為0');
            process.exit(1);
        }
        
        // 讀取模型文件
        const modelData = fs.readFileSync('./demo-ML-project/model_output/cifar10_model.pth');
        
        // 計算原始文件的哈希值
        const originalHash = calculateHash(modelData);
        console.log('原始文件哈希值:', originalHash);
        
        console.log('開始加密模型...');
        const { encryptedData, key } = await encryptData(modelData);
        
        // 計算加密後文件的哈希值
        const encryptedHash = calculateHash(encryptedData);
        console.log('加密後文件哈希值:', encryptedHash);
        
        console.log('模型加密完成');

        console.log('創建Arweave交易...');
        const transaction = await arweave.createTransaction({
            data: encryptedData
        }, wallet);

        transaction.addTag('Content-Type', 'application/octet-stream');
        transaction.addTag('Model-Type', 'CIFAR10');
        transaction.addTag('Encryption-Type', 'AES-256-CBC');
        transaction.addTag('Network', 'testnet');
        
        console.log('簽名交易...');
        await arweave.transactions.sign(transaction, wallet);
        
        console.log('開始上傳...');
        const uploader = await arweave.transactions.getUploader(transaction);

        while (!uploader.isComplete) {
            await uploader.uploadChunk();
            console.log(`上傳進度: ${uploader.pctComplete}% complete`);
        }

        console.log('\n上傳成功！');
        console.log('交易ID:', transaction.id);
        console.log('加密密鑰:', key);
        
        console.log('\n等待交易確認...');
        const status = await arweave.transactions.getStatus(transaction.id);
        console.log('交易狀態:', status);

        const result = {
            network: MAINNET_CONFIG.host,
            transactionId: transaction.id,
            encryptionKey: key,
            originalHash,
            encryptedHash,
            walletAddress: address,
            timestamp: new Date().toISOString()
        };
        
        fs.writeFileSync(
            './model-upload/upload_result.json', 
            JSON.stringify(result, null, 2)
        );
        console.log('\n結果已保存到 upload_result.json');

    } catch (error) {
        console.error('上傳失敗:', error);
        process.exit(1);
    }
}

// 執行上傳
uploadModel();