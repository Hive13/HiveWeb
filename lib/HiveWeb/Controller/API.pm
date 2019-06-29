package HiveWeb::Controller::API;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub begin :Private
	{
	my ($self, $c) = @_;

	if (lc($c->req()->content_type()) eq 'multipart/form-data')
		{
		$c->stash()->{in} = $c->req()->body_parameters();
		}
	else
		{
		$c->stash()->{in} = $c->req()->body_data();
		}
	$c->stash()->{out}  = { response => \0, version => $c->current_version()->{head_id} };
	$c->stash()->{view} = $c->view('JSON');
	}

sub end :Private
	{
	my ($self, $c) = @_;

	$c->detach($c->stash()->{view});
	}

sub index :Path :Args(0)
	{
	my ( $self, $c ) = @_;

	$c->response->body('Matched HiveWeb::Controller::API in API.');
	}

sub status :Local :Args(0)
	{
	my ($self, $c) = @_;
	my $in         = $c->stash()->{in};
	my $out        = $c->stash()->{out};
  $out->{sodas}  = [ $c->model('DB::SodaStatus')->search({},
		{
		prefetch => 'soda_type'
		}) ];

	my $wanted = $in->{temp};

	if ($wanted)
		{
		$wanted = [ $wanted ]
			if (ref($wanted) ne 'ARRAY');
		$wanted = map { $_ => 1 } @$wanted;
		}

	my $items = $c->model('DB::Item')->search({}, { order_by => 'me.display_name' });
	$out->{temps} = [];
	while (my $item = $items->next())
		{
		next
			if ($wanted && !$wanted->{ $item->name() });
		my $temp = $item->search_related('temp_logs', {},
			{
			order_by => { -desc => 'create_time' },
			rows     => 1,
			prefetch => 'item',
			})->first();

		push (@{ $out->{temps} }, $temp)
			if ($temp);
		}
	$out->{response} = \1;
	}

__PACKAGE__->meta->make_immutable;

1;
