// Create a queue, but don't obliterate an existing one!
window.analytics || (window.analytics = []);

// A list of all the methods in analytics.js that we want to stub.
window.analytics.methods = ['identify', 'track', 'trackLink', 'trackForm',
'trackClick', 'trackSubmit', 'page', 'pageview', 'ab', 'alias', 'ready',
'group', 'on', 'once', 'off'];

// Define a factory to create queue stubs. These are placeholders for the
// "real" methods in analytics.js so that you never have to wait for the library
// to load asynchronously to actually track things. The `method` is always the
// first argument, so we know which method to replay the call into.
window.analytics.factory = function (method) {
  return function () {
    var args = Array.prototype.slice.call(arguments);
    args.unshift(method);
    window.analytics.push(args);
    return window.analytics;
  };
};

// For each of our methods, generate a queueing method.
for (var i = 0; i < window.analytics.methods.length; i++) {
  var method = window.analytics.methods[i];
  window.analytics[method] = window.analytics.factory(method);
}

// Define a method that will asynchronously load analytics.js from our CDN.
window.analytics.load = function (apiKey) {

  // Create an async script element for analytics.js based on your API key.
  var script = document.createElement('script');
  script.type = 'text/javascript';
  script.async = true;
  script.src = ('https:' === document.location.protocol ? 'https://' : 'http://') +
                'd2dq2ahtl5zl1z.cloudfront.net/analytics.js/v1/' + apiKey + '/analytics.min.js';

  // Find the first script element on the page and insert our script next to it.
  var firstScript = document.getElementsByTagName('script')[0];
  firstScript.parentNode.insertBefore(script, firstScript);
};

// Add a version so we can keep track of what's out there in the wild.
window.analytics.SNIPPET_VERSION = '2.0.6';

// Load analytics.js with your API key, which will automatically load all of the
// analytics integrations you've turned on for your account. Boosh!
window.analytics.load('cw3dal6k42');

// Make our first page call to load the integrations. If you'd like to manually
// name or tag the page, edit or move this call to use your own tags.
window.analytics.page();

// accommodate Turbolinks
// track page views and form submissions
$(document).on('ready page:change', function() {
  console.log('page loaded');
  analytics.page();
  analytics.trackForm($('#new_visitor'), 'Signed Up');
  analytics.trackForm($('#new_contact'), 'Contact Request');
})
