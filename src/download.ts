import Arweave from 'arweave';
import { createDecipheriv, createHash } from 'crypto';
import * as fs from 'fs';

// Arweave 網絡配置
const MAINNET_CONFIG = {
    host: 'arweave.net',
    port: 443,
    protocol: 'https',
    timeout: 30000,
    logging: true
};

// 初始化 Arweave
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
 * 解密模型數據
 * @param encryptedData 加密的數據
 * @param keyHex 16進制格式的密鑰
 * @returns 解密後的數據
 */
function decryptData(encryptedData: Buffer, keyHex: string): Buffer {
    const key = Buffer.from(keyHex, 'hex');
    const iv = encryptedData.slice(0, 16);
    const encryptedContent = encryptedData.slice(16);
    
    const decipher = createDecipheriv('aes-256-cbc', key, iv);
    return Buffer.concat([decipher.update(encryptedContent), decipher.final()]);
}

async function downloadModel(transactionId: string, decryptionKey: string, expectedOriginalHash?: string, expectedEncryptedHash?: string) {
    try {
        console.log('開始下載模型...');
        
        // 獲取交易數據
        const data = await arweave.transactions.getData(transactionId, {
            decode: true,
            string: false
        });

        if (!data) {
            throw new Error('無法獲取交易數據');
        }

        const encryptedData = Buffer.from(data as Uint8Array);
        
        // 驗證加密數據的哈希值
        const downloadedEncryptedHash = calculateHash(encryptedData);
        console.log('下載的加密數據哈希值:', downloadedEncryptedHash);
        
        if (expectedEncryptedHash && downloadedEncryptedHash !== expectedEncryptedHash) {
            throw new Error('加密數據哈希值不匹配！可能數據已被篡改。');
        }

        console.log('模型下載完成，開始解密...');
        
        // 解密數據
        const decryptedData = decryptData(encryptedData, decryptionKey);
        
        // 驗證解密後數據的哈希值
        const decryptedHash = calculateHash(decryptedData);
        console.log('解密後數據哈希值:', decryptedHash);
        
        if (expectedOriginalHash && decryptedHash !== expectedOriginalHash) {
            throw new Error('解密後數據哈希值不匹配！可能解密過程出錯。');
        }
        
        // 保存解密後的模型
        const outputPath = './demo-ML-project/model_output/downloaded_model.pth';
        fs.mkdirSync('./demo-ML-project/model_output', { recursive: true });
        fs.writeFileSync(outputPath, decryptedData);
        
        console.log(`模型已成功下載並解密，保存在: ${outputPath}`);
        console.log('哈希值驗證成功！數據完整性已確認。');
        
    } catch (error) {
        console.error('下載失敗:', error);
    }
}

// 讀取上傳結果文件（如果存在）
let uploadResult: any = null;
try {
    const resultPath = './model-upload/upload_result.json';
    if (fs.existsSync(resultPath)) {
        uploadResult = JSON.parse(fs.readFileSync(resultPath, 'utf8'));
    }
} catch (error) {
    console.warn('無法讀取上傳結果文件:', error);
}

// 從命令行參數或上傳結果獲取參數
const transactionId = process.argv[2] || uploadResult?.transactionId;
const decryptionKey = process.argv[3] || uploadResult?.encryptionKey;
const originalHash = uploadResult?.originalHash;
const encryptedHash = uploadResult?.encryptedHash;

if (!transactionId || !decryptionKey) {
    console.error('請提供交易ID和解密密鑰');
    console.error('使用方式: ts-node src/download.ts <交易ID> <解密密鑰>');
    process.exit(1);
}

// 執行下載
downloadModel(transactionId, decryptionKey, originalHash, encryptedHash);
