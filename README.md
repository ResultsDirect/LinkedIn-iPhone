LinkedIn API and Authentication for iPhoneOS
==========

LinkedIn has joined the growing number of social networking sites with public APIs. Since many of our clients are professional organizations, it seemed natural to take advantage of that venue in our applications, especially mobile ones. Since no one had build an Objective-C / iPhone client library yet, we began work on our own. (The options are a little broader now, but we were happy to be among the pioneers.)

This code is still young: it will allow your application to authenticate a user to the API via OAuth, and to post status updates, but that's about it. Because we wanted to introduce as few external dependencies as possible, this code manages its own HTTP connections, and does its own XML parsing. As the API support becomes more complete, that's something we may need to revisit. (So if anyone else uses this code, it would be useful to know what other libraries you're using.)


HOWTO
-----

The demo application will require you to fill in your API and Secret keys from LinkedIn. If you don't have an application registered yet, then [go sign up for one](https://www.linkedin.com/secure/developer) now.

When you register your app with LinkedIn, please be sure that you configure it properly.

  * It must be designated as a mobile application in Application Type.
  * The Integration URL must be blank.
  * Most importantly, the OAuth Redirect URL *must* be set to: http://linkedin_oauth/success for the web view's delegate to be notified.

For now, the best reference in terms of how to configure your project is the demo itself. It's pretty straightforward, but these items deserve special mention:

  * If you're already doing any kind of OAuth integration, there's a good chance that your project already includes the OAuthConsumer code. Don't include both copies. But note that the code included here has Ben Gottlieb's changes, so make sure that the code you keep does, too.
  * Xcode 4 is recommended, but a little touchy when it comes to building static library projects in workspaces. (We think the tradeoff is worth it.) You may want to read over [this great article by Jonah](http://blog.carbonfive.com/2011/04/04/using-open-source-static-libraries-in-xcode-4/) if you run into trouble.


TODO
-----
  
  * [Switch from XML to JSON](http://developer.linkedin.com/community/apis/blog/2010/10/25/api-requests-with-json) for data transfer. Currently leaning toward YAJL, but may try to introduce a pluggable parser scheme, a la [RestKit](https://github.com/twotoasters/RestKit).

  * Merge in more of the community's additions, including the new shares API that replaces the status update API we're using. (In the mean time, look at the other forks of this project.)
  
  * Add more functionality to the demo to showcase these additions.
  
  * Investigate [Google's OAuth controllers](http://code.google.com/p/gtm-oauth/), especially given that the OAuth implementation behind that UI is fresher than OAuthConsumer.


Credits
-----

This work owes a debt of gratitude to Ben Gottlieb and his Twitter+OAuth code, which inspired the authentication portion, and to Matt Gemmell's MGTwitterEngine for some ideas about how to structure the API portion. Thanks for all your hard work, and making it Open Source!
> http://github.com/bengottlieb/Twitter-OAuth-iPhone
> http://github.com/mattgemmell/MGTwitterEngine

Included in this project is Ben Gottlieb's snapshot of Kaboomerang's OAuthConsumer library from Google Code, with his addition of an iPhone library project file, and the pin property on the OAToken class. The original code can be found here:
> http://code.google.com/p/oauth/

More recently, we're incorporated changes from some other developers who have been improving the library over the year since we released it:

  * Robert Haining
  * Tom Whipple
  * Andrew Chen


History
-----

- v2.0, ? June 2011:
  - updated for Xcode 4; demo project now builds as a workspace
  - added support for logging out
  - improved demo shows login and logout
  - reorganized headers and protocols to make them easier to include
  - removed problematic NSString+UUID category
  - removed obsolete JavaScript injection process

- v1.0, 5 April 2010: initial public release


License
-----

Copyright &copy; 2010-2011, Results Direct
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of Results Direct nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
