package com.k8s.demo;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/demo")
public class DemoController {

//    @Demo
    @Autowired
    DemoService service;

    @GetMapping
    public String hello() {
        return service.hello();
    }
}
