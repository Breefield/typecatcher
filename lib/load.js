// For writing to the filesystem
var fs = require('fs');
var system = require('system');

// For loading Typekit into
var page = require('webpage').create();
page.settings.userAgent = 'Mozilla/5.0 (iPad; CPU OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A5355d Safari/8536.25';
page.customHeaders = {'Referer': 'localhost'};

var typekit_ID = system.args[1];

// Load he page using page.open b/c that's how customHeaders are used
page.open('./lib/page.html', function (status) {
  if(status == 'fail') phantom.exit();

  page.includeJs('http://use.typekit.net/' + typekit_ID + '.js', function() {

    page.onResourceReceived = function(request) {
      // Pushes only post-page load requests to the STDOUT
      console.log(JSON.stringify(request));
      
      // Must break when we get URL
      if(request.url.match(new RegExp('use\.typekit\.net', 'i'))) {
        phantom.exit();
      }
    }

    page.evaluate(function() {
      try {
        Typekit.load();
      } catch(e) {
        console.log(JSON.stringify(e));
      }
    });

  });

});