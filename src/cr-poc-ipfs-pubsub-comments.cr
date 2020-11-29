
require "json"
require "base64"

channel = "test-comments"
key = "test-comments"

class Message
	include JSON::Serializable

	getter from : String
	getter topicIDs : Array(String)
	getter seqno : String
	@data : String

	def data()
		Base64.decode_string(@data)
	end
end

class Comment
	include JSON::Serializable

	property time = "Never"
	property name : String
	property comment : String

	def update_time()
		@time = Time.utc.to_s( "%a %b %d, %Y" )
	end
end

comments = [] of Comment

File.open( "public/js/comments.js" ) {|f|
	f.gets("\n")
	comments = Array(Comment).from_json( f.gets_to_end )
}

publish = ARGV.includes?("--publish")
spawn {
	loop {
		if publish
			publish = false
			new_hash = %x( set -x; ipfs add -qr public | tail -n1 )
			puts "publishing /ipfs/#{new_hash}"
			%x( set -x; ipfs name publish --key=#{key} /ipfs/#{new_hash} )
			puts "publish complete"
		end
		sleep 1
	}
}

puts "Starting to monitor test-comments"
pubsub = Process.new( "/usr/bin/ipfs", ["pubsub","sub",channel,"--discover","--enc","json"], output: Process::Redirect::Pipe )
pubsub.output.each_line {|line|
	puts line
	msg = Message.from_json(line)
	if msg.data[0] == '{'
		c = Comment.from_json( msg.data )
		c.update_time
		comments.push(c)
		puts "Received comment: #{c.inspect}"

		File.open( "public/js/comments.js", "w" ) {|f|
			f.puts "pubsub_comment.comments ="
			comments.to_json(f)
		}

		publish = true
	end
}

