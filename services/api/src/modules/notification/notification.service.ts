import { messaging } from '../../lib/firebase';
// import { prisma } from '../../lib/prisma'; // 假設你用 prisma 抓資料

export class NotificationService {

    // 基礎發送功能
    async sendPush(token: string, title: string, body: string, data?: any) {
        try {
            return await messaging.send({
                token,
                notification: { title, body },
                data // 可選，傳遞隱藏資訊給 Flutter (例如：跳轉特定頁面)
            });
        } catch (error) {
            console.error('推播發送失敗:', error);
            throw error;
        }
    }

    // 結合業務的發送功能 (例如：有人申請加入)
    async sendJoinRequestNotification(targetUserId: string, requesterName: string) {
        // 1. 透過 Prisma 尋找 targetUserId 的 FCM Token
        // const user = await prisma.user.findUnique({ where: { id: targetUserId } });
        // if (!user?.fcmToken) return; 

        // 2. 發送推播
        // await this.sendPush(user.fcmToken, '新的申請', `${requesterName} 想加入！`);
    }
}