import crypto from 'node:crypto';
import { config } from '../config.js';

/**
 * फ़ाइल भेजें — Lambda पर S3 में रखकर presigned URL, वरना सीधे भेज दें।
 *
 * Lambda का response 6 MB से बड़ा नहीं हो सकता और बाइनरी भेजना झंझट है,
 * इसलिए REPORTS_BUCKET सेट होने पर फ़ाइल S3 पर जाती है और 15 मिनट का
 * डाउनलोड लिंक लौटता है (जो ऐप किसी भी ब्राउज़र/डाउनलोडर से खोल सकता है)।
 */
export async function sendFile(res, { buffer, filename, contentType }) {
  if (!config.reportsBucket) {
    res.setHeader('Content-Type', contentType);
    res.setHeader('Content-Disposition', `inline; filename="${filename}"`);
    return res.send(buffer);
  }

  const { S3Client, PutObjectCommand, GetObjectCommand } = await import('@aws-sdk/client-s3');
  const { getSignedUrl } = await import('@aws-sdk/s3-request-presigner');

  // Neon Object Storage (S3-compatible) या AWS S3 — दोनों एक ही कोड से।
  // Neon buckets के लिए endpoint + credentials env में आते हैं।
  const endpoint =
    process.env.AWS_ENDPOINT_URL_S3 ??
    process.env.AWS_ENDPOINT_URL ??
    process.env.NEON_S3_ENDPOINT ??
    '';
  const s3 = new S3Client({
    region: process.env.AWS_REGION ?? 'ap-south-1',
    ...(endpoint ? { endpoint, forcePathStyle: true } : {}),
  });
  const key = `reports/${new Date().toISOString().slice(0, 10)}/${crypto.randomUUID()}-${filename}`;

  await s3.send(new PutObjectCommand({
    Bucket: config.reportsBucket,
    Key: key,
    Body: buffer,
    ContentType: contentType,
    // अस्थायी फ़ाइलें — 1 दिन बाद S3 lifecycle हटा देगा
    Metadata: { generated: new Date().toISOString() },
  }));

  const url = await getSignedUrl(
    s3,
    new GetObjectCommand({ Bucket: config.reportsBucket, Key: key, ResponseContentDisposition: `inline; filename="${filename}"` }),
    { expiresIn: config.reportsUrlTtl },
  );

  return res.json({
    url,
    filename,
    contentType,
    expiresIn: config.reportsUrlTtl,
    note: 'यह लिंक कुछ मिनट बाद बंद हो जाएगा — फ़ाइल अभी खोल/सेव कर लें',
  });
}

/** क्या S3 पर भेजना सेट है */
export const usesS3 = () => Boolean(config.reportsBucket);
