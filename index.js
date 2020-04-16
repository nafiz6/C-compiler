const express = require("express"),
	bodyParser = require('body-parser'),
	app = express().use(bodyParser.json()),
	fs = require("fs");

const { exec } = require("child_process");


app.listen(process.env.PORT || 8000, () => console.log('webhook is listening'));



app.get('/last-file', (req,res) =>{
	exec("./a.out inp.c", (error, stdout, stderr) => {

	try{
		const contents = fs.readFileSync('code.asm', 'UTF-8');
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



app.post('/', (req,res) =>{
	let body = req.body;
	console.log(req.body);
	fs.writeFile('inp.c', body.code ,function (err) {
		if (err) throw err;
		console.log('Saved!');
	});

	exec("./a.out inp.c", (error, stdout, stderr) => {

	try{
		const contents = fs.readFileSync('code.asm', 'UTF-8');
		if (error) {
			console.log(`error: ${error.message}`);
			return;
		}
		if (stderr) {
			console.log(`stderr: ${stderr}`);
			return;
		}

		const lines = contents.split(/\r?\n/);
		let sendVal={};
		sendVal.code=contents;
		res.status(200).send(sendVal);

	} catch(err){
		console.log(err)
	}});
});




