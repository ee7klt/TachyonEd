Meteor.publish('rewards', () ->
	Rewards.find()
)

Meteor.publish('pledges', () ->
	Pledges.find({type:'stat'})
)

path = Npm.require('path')
base = path.resolve('.')

stripe = Npm.require(base+'/public/node_modules/stripe')(api_key_secret)

Fiber = Npm.require("fibers")
Future = Npm.require("fibers/future")

nodemailer = Npm.require(base+"/public/node_modules/nodemailer")

mail_username = "your_mandrill_username" #e.g. "app1000000@heroku.com"
mail_pass = "your_mandrill_mail_pass"

Meteor.methods

	charge: (amount, token, email, rewards) ->

		fut = new Future()

		stripe.charges.create
			amount: amount
			currency: 'usd'
			card: token
			description: email
			(err,res) ->
				if err
					fut.ret({charged: false, err: err})
				else
					#save pledge
					Fiber(() ->
						Pledges.insert
							type: 'contribution'
							amount: Math.ceil(amount/100)
							email: email
							rewards: rewards
							created_at: Date.now()
					).run()
					fut.ret({charged: true})		

		fut.wait()

	send_email: (email) ->

		#save email
		Pledges.insert
			type: 'tweet'
			email: email
			created_at: Date.now()

		smtpTransport = nodemailer.createTransport("SMTP", {host: "smtp.mandrillapp.com", port: 587, auth: {user: mail_username, pass: mail_pass}})
		file_path = "/path/to/source/file"

		email_html = "Here's your zip file!"

		mailOptions =
			from: 'Bitfunder <test@bitfunder.herokuapp.com>'
			to: email
			subject: "Your File"
			html: email_html
			attachments: [{filePath:file_path}]

		smtpTransport.sendMail(mailOptions, (error, response) ->
			if error
				console.log error
			else
				console.log response
		)

		smtpTransport.close()

