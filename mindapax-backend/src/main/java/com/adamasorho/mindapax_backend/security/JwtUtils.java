package com.adamasorho.mindapax_backend.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

import com.adamasorho.mindapax_backend.model.User;

import java.security.Key;
import java.util.Date;
import java.util.function.Function;

@Component
public class JwtUtils {  
    @Value("${jwt.secret}")
    private String SECRET_KEY;
    @Value("${jwt.expiration}")
    private long EXPIRATION; 
    private final long ACCESS_TOKEN_EXPIRATION = 15 * 60 * 1000; // 15 minutes

    private Key getSignKey() {
        return Keys.hmacShaKeyFor(SECRET_KEY.getBytes());
    }

    public String extractUsername(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    public <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = extractAllClaims(token);
        return claimsResolver.apply(claims);
    }

    public Claims extractAllClaims(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(getSignKey())
                .build()
                .parseClaimsJws(token)
                .getBody();
    }

    public boolean isTokenValid(String token, UserDetails userDetails) {
        final String username = extractUsername(token);
        return username.equals(userDetails.getUsername()) && !isTokenExpired(token);
    }

    private boolean isTokenExpired(String token) {
        return extractAllClaims(token).getExpiration().before(new Date());
    }

    public String generateAccessToken(CustomUserDetails userDetails) {
        return buildToken(userDetails, ACCESS_TOKEN_EXPIRATION);
    }

    public String generateAccessToken(User user) {
        return buildToken(new CustomUserDetails(user), ACCESS_TOKEN_EXPIRATION);
    }

    private String buildToken(CustomUserDetails userDetails, long expiration) {
        return Jwts.builder()
                .setSubject(userDetails.getUsername())
                .claim("firstName", userDetails.getUser().getFirstName())
                .claim("lastName", userDetails.getUser().getLastName())
                .claim("roles", userDetails.getAuthorities().iterator().next().getAuthority())
                .claim("id", userDetails.getUser().getId())
                .setIssuedAt(new Date(System.currentTimeMillis()))
                .setExpiration(new Date(System.currentTimeMillis() + expiration))
                .signWith(getSignKey(), SignatureAlgorithm.HS256)
                .compact();
    }
}

