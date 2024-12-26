import torch
import torch.nn as nn
import torch.optim as optim
import torchvision
import torchvision.transforms as transforms
from torch.utils.data import DataLoader
import os
import json

class CIFAR10Net(nn.Module):
    def __init__(self):
        super(CIFAR10Net, self).__init__()
        self.conv1 = nn.Conv2d(3, 32, 3, padding=1)
        self.conv2 = nn.Conv2d(32, 64, 3, padding=1)
        self.conv3 = nn.Conv2d(64, 64, 3, padding=1)
        self.pool = nn.MaxPool2d(2, 2)
        self.fc1 = nn.Linear(64 * 4 * 4, 512)
        self.fc2 = nn.Linear(512, 10)
        self.dropout = nn.Dropout(0.5)
        self.relu = nn.ReLU()

    def forward(self, x):
        x = self.pool(self.relu(self.conv1(x)))
        x = self.pool(self.relu(self.conv2(x)))
        x = self.pool(self.relu(self.conv3(x)))
        x = x.view(-1, 64 * 4 * 4)
        x = self.dropout(self.relu(self.fc1(x)))
        x = self.fc2(x)
        return x

def train_cifar10(epochs=100, batch_size=128, learning_rate=0.001, save_dir='./demo-ML-project/model_output'):
    # 創建保存目錄
    os.makedirs(save_dir, exist_ok=True)
    
    # 設置設備
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"Using device: {device}")

    # 數據轉換
    transform = transforms.Compose([
        transforms.RandomHorizontalFlip(),
        transforms.RandomCrop(32, padding=4),
        transforms.ToTensor(),
        transforms.Normalize((0.5, 0.5, 0.5), (0.5, 0.5, 0.5))
    ])

    # 加載數據集
    trainset = torchvision.datasets.CIFAR10(root='./demo-ML-project/data', train=True,
                                          download=True, transform=transform)
    trainloader = DataLoader(trainset, batch_size=batch_size,
                           shuffle=True, num_workers=2)

    # 初始化模型
    model = CIFAR10Net().to(device)
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(model.parameters(), lr=learning_rate)

    # 訓練過程
    training_stats = []
    for epoch in range(epochs):
        model.train()
        running_loss = 0.0
        correct = 0
        total = 0
        
        for i, data in enumerate(trainloader, 0):
            inputs, labels = data[0].to(device), data[1].to(device)
            
            optimizer.zero_grad()
            outputs = model(inputs)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()
            
            running_loss += loss.item()
            _, predicted = torch.max(outputs.data, 1)
            total += labels.size(0)
            correct += (predicted == labels).sum().item()
            
            if i % 100 == 99:
                print(f'[Epoch {epoch + 1}, Batch {i + 1}] Loss: {running_loss / 100:.3f}')
                running_loss = 0.0

        # 計算epoch準確率
        accuracy = 100 * correct / total
        print(f'Epoch {epoch + 1} Accuracy: {accuracy:.2f}%')
        
        # 記錄訓練統計
        epoch_stats = {
            'epoch': epoch + 1,
            'accuracy': accuracy,
            'loss': running_loss
        }
        training_stats.append(epoch_stats)

    print('Finished Training')

    # 保存模型和訓練統計
    model_path = os.path.join(save_dir, 'cifar10_model.pth')
    stats_path = os.path.join(save_dir, 'training_stats.json')
    
    torch.save({
        'model_state_dict': model.state_dict(),
        'optimizer_state_dict': optimizer.state_dict(),
        'epochs': epochs,
        'accuracy': accuracy
    }, model_path)
    
    with open(stats_path, 'w') as f:
        json.dump(training_stats, f)

    print(f'Model saved to {model_path}')
    print(f'Training stats saved to {stats_path}')
    
    return model, training_stats

if __name__ == "__main__":
    train_cifar10()