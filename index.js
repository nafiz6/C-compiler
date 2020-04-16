const express = require("express"),
	bodyParser = require('body-parser'),
	app = express().use(bodyParser.json()),
	fs = require("fs");

const { exec } = require("child_process");


app.listen(process.env.PORT || 8000, () => console.log('webhook is listening'));

app.use(function(req, res, next) {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
  next();
});

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
		console.log(contents);
		res.json(contents);

//		res.status(200).send(JSON.stringify(contents));

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


	res.header("Access-Control-Allow-Origin", "*");
	res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");

	let errVal ={code: "",
		log: "Compilation failed. Please recheck code\n"
	}

	exec("./a.out inp.c", (error, stdout, stderr) => {
		if (error) {
			console.log(`error: ${error.message}`);
			errVal.log = errVal.log.concat(error.message).concat("\n");
			res.status(200).send(JSON.stringify(errVal));
			return;
		}
		if (stderr) {
			console.log(`stderr: ${stderr}`);
			errVal.log = errVal.log.concat(stderr);
			res.status(200).send(JSON.stringify(errVal));
			return;
		}
		console.log("Executed");
		try{
		const contents = fs.readFileSync('code.asm', 'UTF-8');
		const logs = fs.readFileSync('log.txt', 'UTF-8');
		
		const lines = contents.split(/\r?\n/);
		let sendVal={
			code:contents,
			log: logs
		};
		console.log(sendVal);
		res.status(200).send(JSON.stringify(sendVal));

	} catch(err){
		errVal.log = errVal.log.concat(err);
		res.status(200).send(JSON.stringify(errVal));
		console.log(err)
	}});
});




