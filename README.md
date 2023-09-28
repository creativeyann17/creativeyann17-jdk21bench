# creativeyann17-jdk21bench

Implementation of the following guide: https://spring.io/blog/2022/10/11/embracing-virtual-threads

## Bench logic:

The test has to be reliable and the conditions of execution similar between tests. 
Using a `docker-compose.yml` with fixed CPU and memory seems a good idea the achieved that.

- `docker-compose.yml` to build and run the API using the same amount of **CPU** and **RAM** between each tests
- `Dockfile` build an optimized **JVM** using **jdeps/jlink** with **JAVA_OPTS** specific for containers
- `experimental.virtual-threads` set to **true|false**
- `BenchController` will simulate our endpoint load, allocating some memory and doing some random pause.
- `bench.sh` will spam the API using `wrk` tool and give us the results

The allocated memory from `BenchController` **isn't** here for nothing, we want the **GC** to works like in real condition
using almost 75% of memory the API (not the JVM) is allowed to use (cf: `-XX:MaxRAMPercentage=75.0`).

## Execution

```shell
docker stats # let's have a look at the live cpu and memory consumption
docker-compose up --build # may take some time
sh ./bench.sh # let's go ...
```
*Switch between Tomcat and Undertow in `pom.xml` before the test*

## Results

I don't want to draw any conclusion. The result are with out-of the box auto-configurations and need *tweaks*.

Aside from that, **it's hard to not give credit to the duo Tomcat + VirtualThreads**. The requests are handled with 
CPU working at 200% (container has 2xCPU) and instantaneously drop to 0% when the bench is done, meaning no requests were 
awaiting in some buffer of the API also meaning the API was efficient and effectively using the resources given to it
and that's important in a **Container/Kubernetes** context, where allocating resources means cost.

Using **Tomcat + VirtualThreads** could allow to reduce the allocated CPU of your containers and have the same performance as a result.

As for the results, see by yourself bellow.

### What next ?

- adding **Netty** in the bench ?
- memory consumption ?

### Tomcat 

#### Virtual-threads ON
```shell
  4 threads and 500 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   208.53ms  168.38ms   1.74s    85.25%
    Req/Sec   660.25    234.07     1.23k    72.93%
  77987 requests in 30.10s, 8.71MB read
Requests/sec:   2591.19
Transfer/sec:    296.37KB

```
#### Virtual-threads OFF
```shell
  4 threads and 500 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   442.00ms  403.03ms   3.58s    91.58%
    Req/Sec   328.77     58.39   530.00     70.14%
  38430 requests in 30.02s, 4.29MB read
Requests/sec:   1279.98
Transfer/sec:    146.25KB
```
### Undertow
```shell
  4 threads and 500 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     4.35s   939.44ms   5.00s    89.34%
    Req/Sec    27.41     15.07    90.00     64.52%
  3149 requests in 30.02s, 439.75KB read
  Socket errors: connect 0, read 0, write 0, timeout 82
Requests/sec:    104.88
Transfer/sec:     14.65KB
```
## Conclusion

