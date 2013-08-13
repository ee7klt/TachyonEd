Session.set('pledged_amount', 0)
Session.set('current_rewards', [])

###
Happens after the DOM loads
###
Meteor.startup ->

	Meteor.subscribe('rewards')
	Meteor.subscribe('pledges')
	Session.set('pledged_amount', 0)

	###
	Twitter share button
	###
	$.getScript("https://platform.twitter.com/widgets.js", () ->

		handleTweet = (event) ->
			if event
				$('#modal-temail').addClass('md-show')

		twttr.widgets.createShareButton(
			'https://bit.ly/12vkVZq'
			document.getElementById('tweet-button')
			(el) ->
				console.log 'button created'
			{text: 'Learn Physics the right way. Go where no class has gone before. Better exam results start here. ', size:'large', count:'none'}
		)

		twttr.events.bind('tweet', handleTweet)
	)


###
(Helper) Functions
###




#Validates email string
valid_email = (email) ->
	re = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
	re.test(email)

#Shows the Stripe transaction form and creates a token
show_transaction_form = ->

	$('.md-modal').removeClass('md-show')

	if Session.get('current_email')

		am = parseInt(Session.get('pledged_amount'))
		if am && am != 0 && typeof am == 'number' && am % 1 == 0
			amount = am
		else
			amount = 10

		amount = amount*100

		token = (res) ->
			$('#modal-charging').addClass('md-show')
			Meteor.call 'charge', amount, res.id, Session.get('current_email'), Session.get('current_rewards'), (err, res) ->
				$('.md-modal').removeClass('md-show')
				if res.charged
					$('#modal-thanks').addClass('md-show')
				else
					$('#modal-error').addClass('md-show')

		StripeCheckout.open
			key:         api_key
			address:     false
			amount:      amount
			currency:    'usd'
			name:        'Onote'
			description: 'Learn better. Retain more. Have fun.'
			panelLabel:  'Pledge'
			token:       token

#Specifies what happens after the user clicks on 'Continue' in the email modal
email_continue = (twitter) ->
	if twitter
		email = $('input#temail-input').val()
		if valid_email(email)
			$('input#temail-input').removeClass('invalid')
			Session.set('current_email', email)
			Meteor.call 'send_email', email
			$('#temail-form').hide()
			$('#temail-thanks').show()
			setTimeout(() ->
				$('.md-modal').removeClass('md-show')
			, 4000)
		else
			$('input#temail-input').addClass('invalid')
	else
		email = $('input#email-input').val()
		if valid_email(email)
			$('input#email-input').removeClass('invalid')
			Session.set('current_email', email)
			if $('input#free-amount').length > 0
				Session.set('pledged_amount', $('input#free-amount').val())
			show_transaction_form()
		else
			$('input#email-input').addClass('invalid')

#Calculates total amount pledged by the user
calculate_total_value = ->

	total_value = 0

	$('input.dollar-amount[readonly=readonly]').each(() ->
		val = $(this).val()
		if val == '' || parseInt(val) % 1 != 0
			$(this).val(5)

		total_value = total_value + parseInt(val)
	)

	if Session.equals('pledged_amount', 0)
		$('#contribute-button').addClass('animated flash')
		setTimeout(() ->
			$('#contribute-button').removeClass('animated flash')
			console.log 'h10'
		, 1000)

	Session.set('pledged_amount', total_value)

#Handles pledging
pledge = (el, pledge) ->

	input = el.find('input.dollar-amount')
	pledge_item = el.find('.feature-pledge')
	pledge_label = el.find('.pledge-label')

	if pledge
		el.addClass('selected')
		pledge_item.addClass('fixed')			
		input.attr('readonly', 'readonly')
		pledge_label.addClass('selected')
		pledge_label.text('PLEDGED!')
		current_rewards = Session.get('current_rewards')
		current_rewards.push({id: el.data('rid'), amount: parseInt(input.val())})
		Session.set('current_rewards', current_rewards)
	else
		el.removeClass('selected')
		pledge_item.removeClass('fixed')
		input.removeAttr('readonly')
		pledge_label.removeClass('selected')
		pledge_label.text('PLEDGE')
		current_rewards = Session.get('current_rewards')
		current_rewards = _.reject(current_rewards, (item) ->
			item.id == el.data('rid')
		)
		Session.set('current_rewards', current_rewards)

	calculate_total_value()

#ESC should close the modal
$(document).keydown (e) =>
  if e.keyCode == 27
  	$('.md-modal:not(#modal-charging)').removeClass('md-show')


###
Templates
###

#Global
Template.global.events

	'mouseenter .feature-block': (ev) ->
		el = $(ev.srcElement)
		if !el.hasClass('selected')
			el.find('input.dollar-amount:not(.fixed)').select().focus()

	'mouseleave .feature-block': (ev) ->
		el = $(ev.srcElement)
		if !el.hasClass('selected')
			el.find('input.dollar-amount:not(.fixed)').blur()

	'click .feature-block': (ev) ->
		el = $(ev.srcElement)

		if el.hasClass('dollar-amount')
			input = el
			el = el.closest('.feature-block')

		if !el.hasClass('feature-block')
			el = el.closest('.feature-block')

		if el.hasClass('selected')
			pledge(el, false)
		else
			pledge(el, true) if !input


	'keyup input.dollar-amount:not(.fixed)': (ev) ->
		input = $(ev.srcElement)
		value = input.val()

		if parseInt(value) > 49
			input.closest('.feature-pledge').find('.reward1').hide()
			input.closest('.feature-pledge').find('.reward2').show()
		else
			input.closest('.feature-pledge').find('.reward1').show()
			input.closest('.feature-pledge').find('.reward2').hide()

	#Dollar inputs should only accept numbers
	'keypress input.number': (ev) ->
		key = ev.keyCode || ev.which
		key = String.fromCharCode(key)
		regex = /[0-9]|\./
		if ( !regex.test(key) )
			ev.returnValue = false
			if(ev.preventDefault)
				ev.preventDefault()


#Modal
Template.modal.pledged = ->
	!Session.equals('pledged_amount', 0)

Template.modal.events

	'click .md-close': ->
		$('.md-modal').removeClass('md-show')

	'click #try-again': ->
		show_transaction_form()

	'click #email-continue': ->
		email_continue()		

	'keypress input#email-input': (e) ->
		email_continue() if e.keyCode == 13

	'click #temail-continue': ->
		email_continue(true)

	'keypress input#temail-input': (e) ->
		email_continue(true) if e.keyCode == 13


#Header
Template.header.total_pledged = ->
	p = Pledges.findOne({type:'stat'})
	if p and p.total_pledged
		p.total_pledged

Template.pledged_amount.amount = ->
	Session.get('pledged_amount')

Template.header.events

	'click #contribute-button': ->

		$('#modal-email').addClass('md-show')
		setTimeout(() ->
			$('input#email-input').focus()
		, 400)

#Grids (feature and reward lists)
Template.feature_grid.features = ->
	Rewards.find( { type: 'feature'}, { sort: { position: 1 } } )

Template.reward_grid.rewards = ->
	Rewards.find( { type: 'reward'}, { sort: { default_amount: 1 } } )





###
Template Helpers
###
Handlebars.registerHelper('format_num', (num) ->
	if num
		num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")
)


