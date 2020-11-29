pubsub_comment = {
	relays: [
		"http://localhost:5001",
		"https://push.polaris-1.work",
	],
	relay_offset: 10000,
	channel: "test-pubsub-comments",
	comments: [],
	comment_area: "#ps-comment-area",

	read_form: function()
	{
		return {
			name: $("#ps-name").val(),
			comment: $("#ps-comment").val()
		}
	},
	format_comment: function( c )
	{
		return "<div class='ps-comment'>" +
		       ("  <h5>" + c.name + " ("  + c.time + ")</h5>") +
		       "  <p>" + c.comment + "</p>" +
		       "</div>"
	},

	submit: function()
	{
		var $p = pubsub_comment

		data = JSON.stringify($p.read_form())

		$.ajax({
			type: "POST",
			url: $p.relay + "/api/v0/pubsub/pub?arg=" + $p.channel + "&arg=" + escape(data),
			data: "",
			dataType: "text"
		})
	},
	init: function()
	{
		this.update()
		this.probe_relay()
	},
	probe_relay: function()
	{
		var $p = pubsub_comment

		var make_handler = function($p,r,i){
			return function(){
				if( i < $p.relay_offset ) {
					$p.relay = r
					$p.relay_offset = i
				}
			}
		}

		for( var i in this.relays ) {
			var r = $p.relays[i]
			$.post( r + "/api/v0/version", make_handler($p,r,i) )
		}
	},
	update: function()
	{
		var $p = pubsub_comment
		var t = ""

		for( i in $p.comments) {
			t += $p.format_comment($p.comments[i])
		}

		$($p.comment_area).html(t)
	}
}

