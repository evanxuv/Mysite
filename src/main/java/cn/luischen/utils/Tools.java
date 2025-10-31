package cn.luischen.utils;

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.channels.FileChannel;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Random;

/**
 * 工具类
 */
public class Tools {
    private static final Random random = new Random();

    public static void copyFileUsingFileChannels(File source, File dest) throws IOException {
        FileChannel inputChannel = null;
        FileChannel outputChannel = null;
        try {
            inputChannel = new FileInputStream(source).getChannel();
            outputChannel = new FileOutputStream(dest).getChannel();
            outputChannel.transferFrom(inputChannel, 0, inputChannel.size());
        } finally {
            if (inputChannel != null) inputChannel.close();
            if (outputChannel != null) outputChannel.close();
        }
    }

    public static int rand(int min, int max) {
        return random.nextInt(max) % (max - min + 1) + min;
    }

    public static String flowAutoShow(double value) {
        int kb = 1024;
        int mb = 1048576;
        int gb = 1073741824;
        double abs = Math.abs(value);
        if (abs > gb) {
            return Math.round(value / gb) + "GB";
        } else if (abs > mb) {
            return Math.round(value / mb) + "MB";
        } else if (abs > kb) {
            return Math.round(value / kb) + "KB";
        }
        return Math.round(value) + "";
    }

    /**
     * AES 加密（Base64 编码）
     */
    public static String enAes(String data, String key) throws Exception {
        Cipher cipher = Cipher.getInstance("AES");
        SecretKeySpec secretKeySpec = new SecretKeySpec(key.getBytes(StandardCharsets.UTF_8), "AES");
        cipher.init(Cipher.ENCRYPT_MODE, secretKeySpec);
        byte[] encryptedBytes = cipher.doFinal(data.getBytes(StandardCharsets.UTF_8));
        return Base64.getEncoder().encodeToString(encryptedBytes);
    }

    /**
     * AES 解密（Base64 解码）
     */
    public static String deAes(String data, String key) throws Exception {
        Cipher cipher = Cipher.getInstance("AES");
        SecretKeySpec secretKeySpec = new SecretKeySpec(key.getBytes(StandardCharsets.UTF_8), "AES");
        cipher.init(Cipher.DECRYPT_MODE, secretKeySpec);
        byte[] cipherTextBytes = Base64.getDecoder().decode(data);
        byte[] decValue = cipher.doFinal(cipherTextBytes);
        return new String(decValue, StandardCharsets.UTF_8);
    }

    /**
     * 判断字符串是否为数字并且非空
     */
    public static boolean isNumber(String str) {
        return str != null && !str.trim().isEmpty() && str.matches("\\d*");
    }
}
