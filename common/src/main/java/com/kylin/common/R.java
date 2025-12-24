package com.kylin.common;

import lombok.Data;
import java.io.Serializable;

@Data
public class R<T> implements Serializable {
    private Integer code; // 状态码 200成功 500失败
    private String msg;   // 提示信息
    private T data;       // 返回数据

    // 成功静态方法
    public static <T> R<T> ok() {
        return ok(null);
    }

    public static <T> R<T> ok(T data) {
        R<T> r = new R<>();
        r.setCode(200);
        r.setMsg("操作成功");
        r.setData(data);
        return r;
    }

    // 失败静态方法
    public static <T> R<T> error(String msg) {
        return error(500, msg);
    }

    public static <T> R<T> error(Integer code, String msg) {
        R<T> r = new R<>();
        r.setCode(code);
        r.setMsg(msg);
        return r;
    }
}
