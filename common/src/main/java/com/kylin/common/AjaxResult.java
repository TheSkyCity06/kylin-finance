package com.kylin.common;

import lombok.Data;
import java.io.Serializable;

/**
 * Ajax 响应结果封装类
 */
@Data
public class AjaxResult<T> implements Serializable {
    private Integer code; // 状态码 200成功 500失败
    private String msg;   // 提示信息
    private T data;       // 返回数据

    // 成功静态方法
    public static <T> AjaxResult<T> success() {
        return success(null);
    }

    public static <T> AjaxResult<T> success(T data) {
        AjaxResult<T> result = new AjaxResult<>();
        result.setCode(200);
        result.setMsg("操作成功");
        result.setData(data);
        return result;
    }

    // 失败静态方法
    public static <T> AjaxResult<T> error(String msg) {
        return error(500, msg);
    }

    public static <T> AjaxResult<T> error(Integer code, String msg) {
        AjaxResult<T> result = new AjaxResult<>();
        result.setCode(code);
        result.setMsg(msg);
        return result;
    }
}

