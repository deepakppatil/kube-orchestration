package com.k8s.demo;

import org.springframework.stereotype.Service;

//@Demo
@Service
public class DemoService {

    public DemoService() {
        System.out.println("Demo Service:: Constructor loaded");
    }

    public String hello() {
        return "This is Springboot Demo Service hosted on k8....VERSION: 0.0.2";
    }
}
