#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2003 Sergey Rusakov.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
#
#----------------------------------------------------------------------------


package ePortal::App::MsgForum::MsgForum;
    use base qw/ePortal::ThePersistent::ExtendedACL/;
    our $VERSION = '4.2';

	use Carp;
	use ePortal::Global;
	use ePortal::Utils;

############################################################################
sub initialize	{	#05/31/00 8:50
############################################################################
    my ($self, %p) = @_;

    $p{DBISource} = 'MsgForum';

    $p{Attributes}{id} ||= {};
    $p{Attributes}{title} ||= {};
    $p{Attributes}{titleurl} ||= {
            dtype => 'YesNo',
            label => {rus => '������� URL ��� ���������',
            eng => 'Use URL in message title'},
        };
    $p{Attributes}{nickname} ||= {
            label => {rus => '�������� ��������', eng => 'Nickname'},
            size => 12,
        };
    $p{Attributes}{memo} ||= {
            label => {rus => '��������', eng => 'Memo'},
            size => 50,
        };
    $p{Attributes}{keepdays} ||= {
            dtype => 'Number',
            label => {rus => "������� ��������� (����)", eng => 'Keep for days'},
            size => 3,
        };
    $p{Attributes}{xacl_post} ||= {
        label => pick_lang(rus => '�������� ����� ����', eng => 'Start new topic'),
    };
    $p{Attributes}{xacl_reply} ||= {
        label => pick_lang(rus => '��������', eng => 'Reply'),
    };
    $p{Attributes}{xacl_edit} ||= {
        label => pick_lang(rus => '������������� ���������', eng => 'Edit messages'),
    };
    $p{Attributes}{xacl_delete} ||= {
        label => pick_lang(rus => '������� ���������', eng => 'Delete messages'),
    };
    $p{Attributes}{xacl_attach} ||= {
        label => pick_lang(rus => '������������ �����', eng => 'Attach a file'),
    };

    $self->SUPER::initialize(%p);
}##initialize



############################################################################
# Description: ����������� �������
#
sub children  { #11/01/00 9:51
############################################################################
	my $self = shift;
	my $orderby = shift || 'msgdate desc';

	my $msg = new ePortal::App::MsgForum::MsgItem;
	$msg->where("forum_id=" . $self->id);
  	$msg->restore_all;
	return $msg;
}##children





############################################################################
# Description: �������� ������ ����� ����������� �������
# Parameters: not null - �������� ����� insert
# Returns: ������ � ��������� ������ ��� undef;
#
sub validate	{	#07/06/00 2:35
############################################################################
	my $self = shift;
	my $beforeinsert = shift;

	# ������� �������� �� ������� ������.
	unless ( $self->Title ) {
		return pick_lang(
				rus => "�� ������� �������� ������",
				eng => "Enter valid forum title");
	}

	undef;
}##validate


############################################################################
sub restore_where	{	#12/24/01 4:02
############################################################################
    my ($self, %p) = @_;

	$p{order_by} = 'title' if not defined $p{order_by};

	$self->SUPER::restore_where(%p);
}##restore_where


############################################################################
# Description: Calculates the number of messages in the board
# Returns: undef or number of messages
#
sub messages	{	#03/01/01 10:58
############################################################################
	my $self = shift;
    my $dbh = $self->dbh;
	my $sql = "SELECT count(*) FROM MsgItem WHERE forum_id=?";

	my $result = $dbh->selectrow_array($sql, undef, $self->id) + 0;

	return $result;
}##messages

############################################################################
# Description: Calculates the number of topics in the board
# Returns: undef or number of topics
#
sub topics    {   #03/01/01 10:58
############################################################################
    my $self = shift;
    my $dbh = $self->dbh;
    my $sql = "SELECT count(*) FROM MsgItem WHERE forum_id=? AND (prev_id is null or prev_id =0)";

    my $result = $dbh->selectrow_array($sql, undef, $self->id) + 0;

    return $result;
}##topics


############################################################################
# Returns: Date|time of last message in the forum
#
############################################################################
sub last_message	{	#05/04/01 10:12
############################################################################
	my $self = shift;

    my $tp = new ePortal::ThePersistent::Support(
        SQL => "SELECT max(msgdate) as max_date FROM MsgItem",
        Attributes => {max_date => { dtype => 'DateTime'}});

    $tp->restore_where(where => "forum_id=?", bind => [$self->id]);
    $tp->restore_next;

    my $result = $tp->max_date;
	if ($result eq '') {
		$result = pick_lang(rus => '�� ��������', eng => 'not known');
	}

	return $result;
}##last_message


############################################################################
sub delete  {   #11/12/02 10:12
############################################################################
    my $self = shift;
    my $id = $self->id;

    my $result = $self->SUPER::delete();    # ACL may claim

    # clean subscription and message items
    if ($result) {
        my $dbh = $self->dbh();
        $result += $dbh->do("DELETE FROM MsgItem WHERE forum_id=?", undef, $self->id);
        $result += $dbh->do("DELETE FROM MsgSubscr WHERE forum_id=?", undef, $self->id);
    }

    return $result;
}##delete


############################################################################
sub parent  {   #04/17/03 11:08
############################################################################
    my $self = shift;
    return $ePortal->Application('MsgForum');
}##parent


############################################################################
# Function: xacl_check_update
# Description: Right to create new Forums
############################################################################
sub xacl_check_update   {   #04/17/03 11:08
############################################################################
    my $self = shift;
    return $ePortal->isAdmin;
}##xacl_check_update

1;

