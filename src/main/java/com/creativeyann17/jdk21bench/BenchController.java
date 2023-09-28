package com.creativeyann17.jdk21bench;

import lombok.extern.slf4j.Slf4j;
import org.apache.commons.io.FileUtils;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Duration;
import java.util.Random;

@Slf4j
@RestController
@RequestMapping("/bench")
public class BenchController {

  private final Random random = new Random(System.currentTimeMillis());

  @GetMapping
  public ResponseEntity<String> bench() throws InterruptedException {
    final long start = System.currentTimeMillis();
    var data = new byte[random.nextInt(1024 * 1024)];
    Thread.sleep(Duration.ofMillis(random.nextLong(300)));
    log.info("Data processed: {} ({}ms)", FileUtils.byteCountToDisplaySize(data.length), System.currentTimeMillis() - start);
    return ResponseEntity.ok("DONE");
  }
}
