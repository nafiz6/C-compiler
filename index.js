var fs = require("fs");

const { exec } = require("child_process");
var http = require('http');

http.createServer(function (req, res) {

    exec("./a.out inp.c", (error, stdout, stderr) => {

  try{  const contents = fs.readFileSync('code.asm', 'UTF-8');
    if (error) {
        console.log(`error: ${error.message}`);
        return;
    }
    if (stderr) {
        console.log(`stderr: ${stderr}`);
        return;
    }
	res.writeHead(200, {'Content-Type': 'text/html'});
	const lines = contents.split(/\r?\n/);
	lines.forEach((line) => {
    res.write(line);
    res.write("\n");	


})

	res.end();
} catch(err){
console.error(err);
}	


});
}).listen(8080);
