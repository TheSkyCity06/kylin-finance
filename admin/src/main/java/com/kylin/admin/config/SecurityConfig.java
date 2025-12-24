package com.kylin.admin.config;

import com.kylin.admin.filter.JwtAuthenticationFilter;
import com.kylin.admin.service.impl.UserDetailsServiceImpl;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.web.util.matcher.AntPathRequestMatcher;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

/**
 * Spring Security 配置类 - 已改进路径匹配与跨域支持
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity(prePostEnabled = true)
@RequiredArgsConstructor
public class SecurityConfig {

    private final UserDetailsServiceImpl userDetailsService;
    private final JwtAuthenticationFilter jwtAuthenticationFilter;

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider();
        authProvider.setUserDetailsService(userDetailsService);
        authProvider.setPasswordEncoder(passwordEncoder());
        return authProvider;
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                // 1. 禁用 CSRF，支持 JWT 无状态模式
                .csrf(AbstractHttpConfigurer::disable)

                // 2. 显式开启跨域支持
                .cors(cors -> cors.configure(http))

                // 3. 配置请求授权路径
                .authorizeHttpRequests(auth -> auth
                        // 放行所有登录、验证码相关的路径，无论前缀如何（使用 AntPathRequestMatcher 支持 ** 模式）
                        .requestMatchers(
                                new AntPathRequestMatcher("/**/auth/login"),
                                new AntPathRequestMatcher("/**/auth/captcha"),
                                new AntPathRequestMatcher("/**/auth/register")
                        ).permitAll()

                        // 放行静态资源（前端页面）
                        .requestMatchers("/", "/*.html", "/favicon.ico").permitAll()
                        .requestMatchers(
                                new AntPathRequestMatcher("/**/*.html"),
                                new AntPathRequestMatcher("/**/*.css"),
                                new AntPathRequestMatcher("/**/*.js")
                        ).permitAll()

                        // 放行工具类接口（如临时密码生成）
                        .requestMatchers(new AntPathRequestMatcher("/**/tool/**")).permitAll()

                        // 其余所有请求必须认证
                        .anyRequest().authenticated()
                )

                // 4. 设置会话管理为无状态
                .sessionManagement(session -> session
                        .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
                )

                // 5. 设置认证提供者
                .authenticationProvider(authenticationProvider())

                // 6. 在用户名密码认证过滤器之前添加 JWT 过滤器
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}