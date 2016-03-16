Pod::Spec.new do |s|
    s.name = 'MWFeedParser'
    s.version = '1.0.1'
    s.license = 'MIT (with amendments)'
    s.summary = 'An RSS and Atom web feed parser for iOS.'
    s.description = 'MWFeedParser is an Objective-C framework for ' \
                    'downloading and parsing RSS (1.* and 2.*) and ' \
                    'Atom web feeds.'
    s.homepage = 'https://github.com/mwaterfall/MWFeedParser'
    s.author = { 'Michael Waterfall' => 'michaelwaterfall@gmail.com' }
    s.source = {
        :git => 'https://github.com/mwaterfall/MWFeedParser.git',
        :tag => 's.version.to_s'
    }

    s.requires_arc = true
    s.ios.deployment_target = '7.0'
    s.tvos.deployment_target = '9.0'

    s.default_subspec = 'Default'

    # Default subspec that includes the most commonly-used components
    s.subspec 'Default' do |default|
        default.dependency 'MWFeedParser/Core'
        default.dependency 'MWFeedParser/NSString+HTML'
        default.dependency 'MWFeedParser/NSDate+InternetDateTime'
    end

    # The Core subspec, containing the library core needed in all cases
    s.subspec 'Core' do |core|
        core.source_files = 'Classes/MWFeedInfo.{h,m}',
                            'Classes/MWFeedItem.{h,m}',
                            'Classes/MWFeedParser.{h,m}',
                            'Classes/MWFeedParser_Private.h'
        core.public_header_files =  'Classes/MWFeedInfo.h',
                                    'Classes/MWFeedItem.h',
                                    'Classes/MWFeedParser.h',
                                    'Classes/MWFeedParser_Private.h'
    end

    s.subspec 'NSString+HTML' do |html|
        html.source_files = 'Classes/NSString+HTML.{h,m}',
                            'Classes/GTMNSString+HTML.{h,m}'
        html.public_header_files =  'Classes/NSString+HTML.h',
                                    'Classes/GTMNSString+HTML.h'
    end

    s.subspec 'NSDate+InternetDateTime' do |internetdatetime|
        internetdatetime.source_files = 'Classes/NSDate+InternetDateTime.{h,m}'
        internetdatetime.public_header_files =  'Classes/NSDate+InternetDateTime.h'
    end

    s.subspec 'Swift' do |swift|
        swift.ios.deployment_target = '8.0'
        swift.osx.deployment_target = '10.9'
        swift.watchos.deployment_target = '2.0'
        swift.tvos.deployment_target = '9.0'
    end
end
