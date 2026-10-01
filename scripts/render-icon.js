const {chromium}=require('playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1024,height:1024}});
 await p.goto('file://'+__dirname+'/icon.html');await p.waitForTimeout(200);
 await (await p.$('#c')).screenshot({path:__dirname+'/../assets/icon-only.png'});await b.close()})();
