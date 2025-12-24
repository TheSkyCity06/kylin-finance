package application;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;


@SpringBootApplication(scanBasePackages = {"com.kylin"})
@MapperScan("com.kylin.**.mapper")
public class KylinApplication {
    public static void main(String[] args) {
        SpringApplication.run(KylinApplication.class, args);
        System.out.println("(♥◠‿◠)ﾉﾞ  麒麟财务管理系统启动成功   ლ(´ڡ`ლ)ﾞ");
    }
}