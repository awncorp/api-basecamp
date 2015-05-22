package API::Basecamp::Class;

use Extorter;

# VERSION

sub import {
    my $class  = shift;
    my $target = caller;

    $class->extort::into($target, '*Data::Object::Class');
    $class->extort::into($target, '*API::Basecamp::Signature');
    $class->extort::into($target, '*API::Basecamp::Type');

    return;
}

1;
