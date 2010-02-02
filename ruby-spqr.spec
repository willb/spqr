%{!?ruby_sitelib: %global ruby_sitelib %(ruby -rrbconfig -e 'puts Config::CONFIG["sitelibdir"] ')}
%define rel 0.1

Summary: SPQR:  {Schema Processor|Straightforward Publishing} for QMF agents in Ruby
Name: ruby-spqr
Version: 0.2.0
Release: %{rel}%{?dist}
Group: Applications/System
License: ASL 2.0
URL: http://git.fedorahosted.org/git/grid/spqr.git
Source0: %{name}-%{version}-%{rel}.tar.gz
BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Requires: ruby
Requires: ruby-qmf
BuildArch: noarch

%description
SPQR makes it very simple to expose methods on Ruby objects over QMF.

%package -n spqr-gen
Summary: Generates an spqr app from an xml schema
Group: Applications/System
Requires: ruby-spqr

%description -n spqr-gen
A tool that will generate an spqr application from an xml schema file

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/%{_bindir}
mkdir -p %{buildroot}/%{ruby_sitelib}/spqr
cp -f lib/spqr/app.rb %{buildroot}/%{ruby_sitelib}/spqr
cp -f lib/spqr/codegen.rb %{buildroot}/%{ruby_sitelib}/spqr
cp -f lib/spqr/constants.rb %{buildroot}/%{ruby_sitelib}/spqr
cp -f lib/spqr/manageable.rb %{buildroot}/%{ruby_sitelib}/spqr
cp -f lib/spqr/spqr.rb %{buildroot}/%{ruby_sitelib}/spqr
cp -f lib/spqr/utils.rb %{buildroot}/%{ruby_sitelib}/spqr
cp -f bin/spqr-gen.rb %{buildroot}/%{_bindir}

%clean
rm -rf %{buildroot}

%files
%defattr(-, root, root, -)
%doc LICENSE README.rdoc CHANGES TODO VERSION
%doc examples
%{ruby_sitelib}/spqr

%files -n spqr-gen
%defattr(-, root, root, -)
%doc LICENSE
%defattr(755, root, root, -)
%{_bindir}/spqr-gen.rb

%changelog
* Tue Feb  2 2010  <rrati@fedora12-test> - 0.2.0-0.1
- Initial package
