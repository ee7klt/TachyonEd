#Bitfunder

##Getting Bitfunder up and running locally

###Install the tools

NVM

    curl https://raw.github.com/creationix/nvm/master/install.sh | sh


Node.js

    nvm install v0.10.13


Meteor

    curl https://install.meteor.com | /bin/sh


###Run locally

Start the server

    cd bitfunder
    meteor

Populate the database

    cd bitfunder
    meteor mongo
    > use meteor;
    > db.pledges.insert({"type":"stat","total_pledged":20563});
    > db.rewards.insert({"type": "feature","title": "Search","subtitle": "Video search and discovery that actually works.","description": "Your description here.","fixed": false,"default_amount": 15,"pledged": 541,"backers": 27,"position": 3});
    > ...

Set up Stripe

Set your api keys in lib/collections.coffee. Visit Stripe.com and create an account to get your API keys.


##Deploying Bitfunder to Heroku

This assumes you already have a Heroku account and keys set up on your machine. All commands below should be done in your app directory.

    git init
    git add .
    git commit -a -m "First Bitfunder Commit"

    heroku create [your_appname] --stack cedar --buildpack https://github.com/v8squirrel/heroku-buildpack-meteor.git
    git remote add heroku git@heroku.com:[appname].git

    heroku addons:add mongohq:sandbox
    heroku config:set MONGO_URL=mongodb://[username]:[password]@dharma.mongohq.com:10038/app123456 (mongo url from above)

    git push heroku master

Set up Mandrill to send email

    heroku addons:add mandrill:starter

Then set your mail_pass and username in server.coffee.



   