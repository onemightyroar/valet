Valet
===

Realtime node.js + socket.io server in a box.
---

Valet is a simple server built on node.js and socket.io. You can deploy it locally with one command, or remotely with a few clicks. Clever namespaces allow you to use Valet for multiple projects simultaneously.

Check out [this blog post](http://buildinternet.com/2013/08/valet/) for some background on Valet.

Running Valet locally
---

Install the Valet module from npm with:

    sudo npm install -g valet

Then run it locally with:

    valet

You can verify that Valet is running by visiting `http://localhost:9200` in your browser. You should see `valet version 0.1.0`.

Deploying Valet to EC2
---

* Open up opsworks and spin up a new "micro" instance.
* Create a new app (type=node.js), and **name it "valet"**.
* Point the app to the Valet github repository. No SSH key required.
* Deploy your app. Valet will be pulled from github.

Deploying Valet to Nodejitsu
---

Coming soon...


Namespaces
---

Namespaces split clients into groups, to allow many projects to use a single Valet instance simultaneously.

Clients (frontends, devices, or even other servers) determine what namespaces they want to join by connecting to a specific URL. Multiple namespaces can be joined by calling `connect` multiple times (only one websocket connection will actually be used).

For example, to join the `/temperature` and `/humidity` namespaces, your client would have code that looks something like:

	temperature = io.connect('http://localhost:9200/temperature')
	humidity = io.connect('http://localhost:9200/humidity')

Valet extends socket.io's namespaces in a useful way: if you use more complex namespaces, your events and data will "bubble up". For example, data you send to a namespace like `/buildings/123/rooms/456/temperature` will be emitted on the following three namespaces:

	/buildings/123/rooms/456/temperature
	/buildings/123/temperature
	/temperature

This means that you can listen to `/buildings/123/rooms/456/temperature` to get events from temperature sensors in room 456, `/buildings/123/temperature` to get events from all of the temperature sensors in building 123, or `/temperature` to get events from all of the temperature sensors, everywhere.

Sending data to Valet
---

You can pass data to Valet by either sending a POST request to your Valet server, or by emitting a socket event called "post". For example, to send data from your terminal using CURL:

	curl -X POST -H "Content-Type: application/json" -d '{"event":"reading","data":{"temp":83.3826}}' http://localhost:9200/buildings/123/rooms/456/temperature

To send the same data using a socket is a two step process - first, you must connect to your Valet server **on the root namespace**. Then, emit an event called `post` containing the `event`, `namespace`, and `data` you would like to emit. For example:

	temperature = io.connect('http://localhost:9200');
	temperature.emit('post',{
		event:"reading",
		namespace:"/buildings/123/rooms/456/temperature",
		data:{temp:83.3826}
	});

In either case, an event called `reading` with data `{temp:83.3826}` will be emitted on the three namespaces described in the "Namespaces" section above.

Clients
---

Anything that can run socket.io can be a Valet client. Simply require socket.io on your client, connect on whatever namespaces you like, and listen for events.

Here is an example client that listens for temperature readings. To demonstrate the namespace "event bubbling" behavior described above, this example listens for events on the `/buildings/123/temperature` namespace, even though they will be sent to the server on the `/buildings/123/rooms/456/temperature` namespace.

	```HTML
	<!DOCTYPE html>
	<head>

		<!-- Valet serves up socket.io.js on a special endpoint -->
		<script src="http://localhost:9200/socket.io/socket.io.js"></script>

		<script type="text/javascript">

			// Connect on the "buildingTemp" namespace
			var buildingTemp = io.connect('/buildings/123/temperature');

			// "Connect" events are fired when the connection happens successfully
			buildingTemp.on('connect',function(){
				console.log('connected to the "buildingTemp" namespace!');
			});

			// Listen for the "reading" event we will be POSTing
			buildingTemp.on('reading',function(data){
				console.log('Got data on the "buildingTemp" namespace!');
				console.log(data);
			});
		</script>
	</head>
	<body></body>
	```

## Contributing
In lieu of a formal styleguide, take care to maintain the existing coding style. Add unit tests for any new or changed functionality. Lint and test your code using [Grunt](http://gruntjs.com/).

Faq
---

* Valet stopped immediately after starting, with no error message. What's up?
    * Usually this is due to a port conflict - make sure you don't have any other instances of Valet running, or anything else on port 9200. You can also change the default port in the config.json file in the Valet root folder.

## License
Copyright (c) 2013 One Mighty Roar
Licensed under the MIT license.
