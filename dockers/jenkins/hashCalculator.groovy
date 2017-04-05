#!/usr/bin/env groovy
@Grab(group='org.apache.commons', module='commons-lang3', version='3.4')

import org.apache.commons.lang3.StringEscapeUtils;
import java.security.MessageDigest;

def String toHexString(byte[] data) {
    start = 0;
    len = data.length
    StringBuilder buf = new StringBuilder();
    for( int i=0; i<len; i++ ) {
        int b = data[start+i]&0xFF;
        if(b<16)    buf.append('0');
        buf.append(Integer.toHexString(b));
    }
    return buf.toString();
}

if (args.length != 1) {
	println "Missing file name"
	System.exit(-1)
}

script = new File(args[0]).getText("UTF-8")
script = StringEscapeUtils.unescapeXml(script.replaceAll("(?sm).*<script>(.*)<\\/script>.*",'$1'))

MessageDigest digest = MessageDigest.getInstance("SHA-1")
digest.update("groovy".getBytes("UTF-8"))
digest.update((byte) ':');
digest.update(script.getBytes("UTF-8"));
println toHexString(digest.digest())

