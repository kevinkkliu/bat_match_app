import * as admin from 'firebase-admin';
// 這裡可能需要引入你的 src/lib/config.ts 來取得憑證路徑

if (!admin.apps.length) {
    admin.initializeApp({
        // 根據你的環境變數設定，可能是 applicationDefault() 或 cert(json路徑)
        credential: admin.credential.applicationDefault(),
    });
}

// 導出 messaging 實例供業務邏輯使用
export const messaging = admin.messaging();
export default admin;