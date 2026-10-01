const {chromium}=require('playwright');const fs=require('fs');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:2732,height:2732}});
 const icon='data:image/png;base64,'+fs.readFileSync(__dirname+'/../assets/icon-only.png').toString('base64');
 await p.setContent(`<canvas id=c width=2732 height=2732></canvas><script>const x=c.getContext('2d');x.fillStyle='#0b0a0f';x.fillRect(0,0,2732,2732);const i=new Image();i.onload=()=>{x.save();x.beginPath();x.arc(1366,1366,420,0,Math.PI*2);x.clip();x.drawImage(i,1366-460,1366-460,920,920);x.restore();document.title='ok'};i.src='${icon}'</script>`);
 await p.waitForFunction(()=>document.title==='ok');const buf=await (await p.$('#c')).screenshot();
 for(const f of ['splash-2732x2732.png','splash-2732x2732-1.png','splash-2732x2732-2.png'])fs.writeFileSync(__dirname+'/../ios/App/App/Assets.xcassets/Splash.imageset/'+f,buf);
 fs.writeFileSync(__dirname+'/../assets/splash.png',buf);await b.close()})();
