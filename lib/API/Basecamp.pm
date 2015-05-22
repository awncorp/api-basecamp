# ABSTRACT: Perl 5 API wrapper for Basecamp
package API::Basecamp;

use API::Basecamp::Class;

extends 'API::Basecamp::Client';

use Carp ();
use Scalar::Util ();

# VERSION

has account => (
    is       => 'rw',
    isa      => STRING,
    required => 1,
);

has identifier => (
    is       => 'rw',
    isa      => STRING,
    default  => 'API::Basecamp (Perl)',
);

has username => (
    is       => 'rw',
    isa      => STRING,
    required => 1,
);

has password => (
    is       => 'rw',
    isa      => STRING,
    required => 1,
);

has version => (
    is       => 'rw',
    isa      => INTEGER,
    default  => 1,
);

method AUTOLOAD () {
    my ($package, $method) = our $AUTOLOAD =~ /^(.+)::(.+)$/;
    Carp::croak "Undefined subroutine &${package}::$method called"
        unless Scalar::Util::blessed $self && $self->isa(__PACKAGE__);

    # return new resource instance dynamically
    return $self->resource($method, @_);
}

method BUILD () {
    my $identifier = $self->identifier;
    my $username   = $self->username;
    my $password   = $self->password;
    my $account    = $self->account;
    my $version    = $self->version;

    my $userinfo   = "$username:$password";
    my $agent      = $self->user_agent;
    my $url        = $self->url;

    $agent->transactor->name($identifier);

    $url->path("/$account/api/v$version");
    $url->userinfo($userinfo);

    return $self;
}

method PREPARE ($ua, $tx, %args) {
    my $headers = $tx->req->headers;
    my $url     = $tx->req->url;

    # default headers
    $headers->header('Content-Type' => 'application/json');

    # append path suffix
    $url->path("@{[$url->path]}.json") if $url->path !~ /\.json$/;
}

method action ($method, %args) {
    $method = uc($method || 'get');

    # execute transaction and return response
    return $self->$method(%args);
}

method create (%args) {
    # execute transaction and return response
    return $self->POST(%args);
}

method delete (%args) {
    # execute transaction and return response
    return $self->DELETE(%args);
}

method fetch (%args) {
    # execute transaction and return response
    return $self->GET(%args);
}

method resource (@segments) {
    # build new resource instance
    my $instance = __PACKAGE__->new(
        debug      => $self->debug,
        fatal      => $self->fatal,
        retries    => $self->retries,
        timeout    => $self->timeout,
        user_agent => $self->user_agent,
        account    => $self->account,
        identifier => $self->identifier,
        username   => $self->username,
        password   => $self->password,
        version    => $self->version,
    );

    # resource locator
    my $url = $instance->url;

    # modify resource locator if possible
    $url->path(join '/', $self->url->path, @segments);

    # return resource instance
    return $instance;
}

method update (%args) {
    # execute transaction and return response
    return $self->PUT(%args);
}

1;

=encoding utf8

=head1 SYNOPSIS

    use API::Basecamp;

    my $basecamp = API::Basecamp->new(
        username   => 'USERNAME',
        password   => 'PASSWORD',
        identifier => 'APPLICATION NAME',
        account    => 'ACCOUNT NUMBER',
    );

    $basecamp->debug(1);
    $basecamp->fatal(1);

    my $project = $basecamp->projects('605816632');
    my $results = $project->fetch;

    # after some introspection

    $project->update( ... );

=head1 DESCRIPTION

This distribution provides an object-oriented thin-client library for
interacting with the Basecamp (L<http://basecamp.com>) API. For usage and
documentation information visit L<https://github.com/basecamp/bcx-api>.

=cut

=head1 THIN CLIENT

A thin-client library is advantageous as it has complete API coverage and
can easily adapt to changes in the API with minimal effort. As a thin-client
library, this module does not map specific HTTP requests to specific routines,
nor does it provide parameter validation, pagination, or other conventions
found in typical API client implementations, instead, it simply provides a
simple and consistent mechanism for dynamically generating HTTP requests.
Additionally, this module has support for debugging and retrying API calls as
well as throwing exceptions when 4xx and 5xx server response codes are
returned.

=cut

=head2 Building

    my $project = $basecamp->projects('605816632');

    $project->action; # GET /projects/605816632
    $project->action('head'); # HEAD /projects/605816632
    $project->action('patch'); # PATCH /projects/605816632

Building up an HTTP request object is extremely easy, simply call method names
which correspond to the API's path segments in the resource you wish to execute
a request against. This module uses autoloading and returns a new instance with
each method call. The following is the equivalent:

=head2 Chaining

    my $project = $basecamp->resource('projects', '605816632');

    # or

    my $projects = $basecamp->projects;
    my $project  = $projects->resource('605816632');

    # then

    $project->action('put', %args); # PUT /projects/605816632

Because each call returns a new API instance configured with a resource locator
based on the supplied parameters, reuse and request isolation are made simple,
i.e., you will only need to configure the client once in your application.

=head2 Fetching

    my $projects = $basecamp->projects;

    # query-string parameters

    $projects->fetch( query => { ... } );

    # equivalent to

    my $projects = $basecamp->resource('projects');

    $projects->action( get => ( query => { ... } ) );

This example illustrates how you might fetch an API resource.

=head2 Creating

    my $projects = $basecamp->projects;

    # content-body parameters

    $projects->create( data => { ... } );

    # query-string parameters

    $projects->create( query => { ... } );

    # equivalent to

    $basecamp->resource('projects')->action(
        post => ( query => { ... }, data => { ... } )
    );

This example illustrates how you might create a new API resource.

=head2 Updating

    my $projects = $basecamp->projects;
    my $project  = $projects->resource('605816632');

    # content-body parameters

    $project->update( data => { ... } );

    # query-string parameters

    $project->update( query => { ... } );

    # or

    my $project = $basecamp->projects('605816632');

    $project->update(...);

    # equivalent to

    $basecamp->resource('projects')->action(
        put => ( query => { ... }, data => { ... } )
    );

This example illustrates how you might update a new API resource.

=head2 Deleting

    my $projects = $basecamp->projects;
    my $project  = $projects->resource('605816632');

    # content-body parameters

    $project->delete( data => { ... } );

    # query-string parameters

    $project->delete( query => { ... } );

    # or

    my $project = $basecamp->projects('605816632');

    $project->delete(...);

    # equivalent to

    $basecamp->resource('projects')->action(
        delete => ( query => { ... }, data => { ... } )
    );

This example illustrates how you might delete an API resource.

=cut

=head2 Transacting

    my $projects = $basecamp->resource('projects', '605816632');

    my ($results, $transaction) = $projects->action( ... );

    my $request  = $transaction->req;
    my $response = $transaction->res;

    my $headers;

    $headers = $request->headers;
    $headers = $response->headers;

    # etc

This example illustrates how you can access the transaction object used
represent and process the HTTP transaction.

=cut

=attr account

    $basecamp->account;
    $basecamp->account('ACCOUNT');

The account parameter should be set to the account holder's account ID number.

=cut

=attr identifier

    $basecamp->identifier;
    $basecamp->identifier('IDENTIFIER');

The identifier parameter should be set to a string that identifies your application.

=cut

=attr password

    $basecamp->password;
    $basecamp->password('PASSWORD');

The password parameter should be set to the account holder's password.

=cut

=attr username

    $basecamp->username;
    $basecamp->username('USERNAME');

The username parameter should be set to the account holder's username.

=cut

=attr debug

    $basecamp->debug;
    $basecamp->debug(1);

The debug attribute if true prints HTTP requests and responses to standard out.

=cut

=attr fatal

    $basecamp->fatal;
    $basecamp->fatal(1);

The fatal attribute if true promotes 4xx and 5xx server response codes to
exceptions, a L<API::Basecamp::Exception> object.

=cut

=attr retries

    $basecamp->retries;
    $basecamp->retries(10);

The retries attribute determines how many times an HTTP request should be
retried if a 4xx or 5xx response is received. This attribute defaults to 0.

=cut

=attr timeout

    $basecamp->timeout;
    $basecamp->timeout(5);

The timeout attribute determines how long an HTTP connection should be kept
alive. This attribute defaults to 10.

=cut

=attr url

    $basecamp->url;
    $basecamp->url(Mojo::URL->new('https://basecamp.com'));

The url attribute set the base/pre-configured URL object that will be used in
all HTTP requests. This attribute expects a L<Mojo::URL> object.

=cut

=attr user_agent

    $basecamp->user_agent;
    $basecamp->user_agent(Mojo::UserAgent->new);

The user_agent attribute set the pre-configured UserAgent object that will be
used in all HTTP requests. This attribute expects a L<Mojo::UserAgent> object.

=cut

=method action

    my $result = $basecamp->action($verb, %args);

    # e.g.

    $basecamp->action('head', %args);    # HEAD request
    $basecamp->action('options', %args); # OPTIONS request
    $basecamp->action('patch', %args);   # PATCH request


The action method issues a request to the API resource represented by the
object. The first parameter will be used as the HTTP request method. The
arguments, expected to be a list of key/value pairs, will be included in the
request if the key is either C<data> or C<query>.

=cut

=method create

    my $results = $basecamp->create(%args);

    # or

    $basecamp->POST(%args);

The create method issues a C<POST> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=cut

=method delete

    my $results = $basecamp->delete(%args);

    # or

    $basecamp->DELETE(%args);

The delete method issues a C<DELETE> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=cut

=method fetch

    my $results = $basecamp->fetch(%args);

    # or

    $basecamp->GET(%args);

The fetch method issues a C<GET> request to the API resource represented by the
object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=cut

=method update

    my $results = $basecamp->update(%args);

    # or

    $basecamp->PUT(%args);

The update method issues a C<PUT> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=cut

=resource accesses

    $basecamp->projects('605816632')->accesses;

The accesses method returns a new instance representative of the API
I<Accesses> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://github.com/basecamp/bcx-api/blob/master/sections/accesses.md>.

=cut

=resource attachments

    $basecamp->attachments;

The attachments method returns a new instance representative of the API
I<Attachments> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://github.com/basecamp/bcx-api/blob/master/sections/attachments.md>.

=cut

=resource calendar_events

    $basecamp->calendar_events;

The calendar_events method returns a new instance representative of the API
I<Calendar Events> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<>.

=cut

=resource calendars

    $basecamp->calendars;

The calendars method returns a new instance representative of the API
I<Calendars> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://github.com/basecamp/bcx-api/blob/master/sections/calendars.md>.

=cut

=resource comments

    $basecamp->projects('605816632')->comments;

The comments method returns a new instance representative of the API
I<Comments> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://github.com/basecamp/bcx-api/blob/master/sections/comments.md>.

=cut

=resource documents

    $basecamp->documents;

The documents method returns a new instance representative of the API
I<Documents> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://github.com/basecamp/bcx-api/blob/master/sections/documents.md>.

=cut

=resource events

    $basecamp->events;

The events method returns a new instance representative of the API
I<Events> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://github.com/basecamp/bcx-api/blob/master/sections/events.md>.

=cut

=resource groups

    $basecamp->groups;

The groups method returns a new instance representative of the API
I<Groups> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://github.com/basecamp/bcx-api/blob/master/sections/groups.md>.

=cut

=resource messages

    $basecamp->projects('605816632')->messages;

The messages method returns a new instance representative of the API
I<Messages> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://github.com/basecamp/bcx-api/blob/master/sections/messages.md>.

=cut

=resource people

    $basecamp->people;

The people method returns a new instance representative of the API
I<People> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://github.com/basecamp/bcx-api/blob/master/sections/people.md>.

=cut

=resource project_templates

    $basecamp->project_templates;

The project_templates method returns a new instance representative of the API
I<Project Templates> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://github.com/basecamp/bcx-api/blob/master/sections/project_templates.md>.

=cut

=resource projects

    $basecamp->projects;

The projects method returns a new instance representative of the API
I<Projects> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://github.com/basecamp/bcx-api/blob/master/sections/projects.md>.

=cut

=resource stars

    $basecamp->stars;

The stars method returns a new instance representative of the API
I<Stars> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://github.com/basecamp/bcx-api/blob/master/sections/stars.md>.

=cut

=resource todo_lists

    $basecamp->todo_lists;

The todo_lists method returns a new instance representative of the API
I<Todo Lists> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://github.com/basecamp/bcx-api/blob/master/sections/todolists.md>.

=cut

=resource todos

    $basecamp->projects('605816632')->todos;

The todos method returns a new instance representative of the API
I<Todos> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://github.com/basecamp/bcx-api/blob/master/sections/todos.md>.

=cut

=resource topics

    $basecamp->topics;

The topics method returns a new instance representative of the API
I<Topics> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://github.com/basecamp/bcx-api/blob/master/sections/topics.md>.

=cut

=resource uploads

    $basecamp->projects('605816632')->uploads;

The uploads method returns a new instance representative of the API
I<Uploads> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://github.com/basecamp/bcx-api/blob/master/sections/uploads.md>.

=cut

