import Java from 'frida-java-bridge';
(globalThis as any).Java = Java;
require('./script.js');
