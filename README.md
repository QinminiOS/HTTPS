##AFNetworking Nginx HTTPS自签名服务器安全通信


A.对于后台服务器所配置动证书如果是经过CA机构认证颁发的，那么用户用AFNetworking来访问后台接口完全无感觉，就和http一样的方式。

B.但是一个HTTPS的证书如果是知名CA机构认证颁发的，那么就会有问题，AFNetworking默认拒绝和这样的后台服务器通信，因为验证通不过，就和大家网页打开12306网站抢票一样，那个证书也不是经过CA颁发的，而是铁道部自己签名的一个证书。所以，对于中小型初创或是成长型公司来说，买一个https的证书也是需要花费不少费用的。



AFSecurityPolicy分三种验证模式：

AFSSLPinningModeNone

这个模式表示不做SSL pinning，只跟浏览器一样在系统的信任机构列表里验证服务端返回的证书。若证书是信任机构签发的就会通过，若是自己服务器生成的证书，这里是不会通过的。

AFSSLPinningModeCertificate

这个模式表示用证书绑定方式验证证书，需要客户端保存有服务端的证书拷贝，这里验证分两步，第一步验证证书的域名/有效期等信息，第二步是对比服务端返回的证书跟客户端返回的是否一致。

这里还没弄明白第一步的验证是怎么进行的，代码上跟去系统信任机构列表里验证一样调用了SecTrustEvaluate，只是这里的列表换成了客户端保存的那些证书列表。若要验证这个，是否应该把服务端证书的颁发机构根证书也放到客户端里？

AFSSLPinningModePublicKey

这个模式同样是用证书绑定方式验证，客户端要有服务端的证书拷贝，只是验证时只验证证书里的公钥，不验证证书的有效期等信息。只要公钥是正确的，就能保证通信不会被窃听，因为中间人没有私钥，无法解开通过公钥加密的数据。


1.生成服务器的KEY和证书签名

openssl genrsa -des3 -out server.key 1024
openssl req -new -key server.key -out server.csr
openssl rsa -in server.key -out server_nopwd.key
openssl x509 -req -days 365 -in server.csr -signkey server_nopwd.key -out server.crt

2.证书格式转换 由于iOS端Apple的API需要der格式证书，故用如下命令转换

openssl x509 -outform der -in server.crt -out client.der

3.nginx配置
```OC
server {
    listen 80;#HTTP默认端口80
    server_name tv.diveinedu.com;#主机名,与HTTP请求头域的HOST匹配
    access_log  /var/log/nginx/tv.diveinedu.com.log;#访问日志路径
    return 301 https://$server_name$request_uri;#强制把所有http访问跳转到https
}

server {
    listen 443;#HTTPS默认端口443
    ssl on;#打开SSL安全Socket
    ssl_certificate      /usr/local/etc/nginx/server.crt;#证书文件路径
    ssl_certificate_key  /usr/local/etc/nginx/server_nopwd.key;#私钥文件路径

    #server_name xxx.com;#主机名,与HTTP请求头域的HOST匹配
    access_log  logs/host.access.log;#访问日志路径
    location / {
        root /var/www/;#网站文档根目录
        index index.php index.html;#默认首页
    }
}
```OC

4.示例代码

NSString *certFilePath = [[NSBundle mainBundle] pathForResource:@"client" ofType:@"der"];
NSData *certData = [NSData dataWithContentsOfFile:certFilePath];
NSSet *certSet = [NSSet setWithObject:certData];
AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey withPinnedCertificates:certSet];
securityPolicy.allowInvalidCertificates = YES;
securityPolicy.validatesDomainName = NO;
_manager.securityPolicy = securityPolicy;

AFHTTPResponseSerializer *serializer = [[AFHTTPResponseSerializer alloc] init];
serializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html", nil];
_manager.responseSerializer = serializer;

[_manager GET:@"https://192.168.47.112/" parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
    
} success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
    NSLog(@"%@", [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
} failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
    NSLog(@"%@",[error localizedDescription]);
}];

