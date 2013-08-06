@Rewards = new Meteor.Collection('rewards')
@Pledges = new Meteor.Collection('pledges')

#Your Stripe publishable and secret keys. Visit Stripe.com for more info
@api_key = 'pk_live_publishablekeyhere'
@api_key_secret = 'sk_live_secrretkeyhere'