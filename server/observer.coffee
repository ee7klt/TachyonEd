query = Pledges.find( { created_at : { $gt: Date.now() } } )
handle = query.observeChanges
	added: (id, doc) =>
		if doc.type == 'contribution'

			if doc.rewards
				_.all(doc.rewards, (reward) ->
					Rewards.update( { _id: reward.id }, { $inc: { pledged: reward.amount, backers: 1 } } )
				)

			Pledges.update( { type: 'stat'}, { $inc: { total_pledged: doc.amount } } )
