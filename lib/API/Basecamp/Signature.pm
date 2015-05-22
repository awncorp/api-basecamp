package API::Basecamp::Signature;

use parent 'Function::Parameters';

# VERSION

@Function::Parameters::type_reifiers = (
    *_reify_type_default = sub {
        require Type::Registry;
        require API::Basecamp::Type;
        my $registry = Type::Registry->for_me;
           $registry->add_types(-Standard);
           $registry->add_types('API::Basecamp::Type');
           $registry->lookup($_[0]);
    }
);

1;
