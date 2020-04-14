var express = require("express");
var app = express();
var fs = require("fs");

const { exec } = require("child_process");
var http = require('http');

app.get('/', (req,res) =>{



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

	const lines = contents.split(/\r?\n/);








    res.status(200).send(contents);

} catch(err){
console.log(err)
}});
});




app.listen(process.env.PORT || 8000, () => console.log('webhook is listening'));


