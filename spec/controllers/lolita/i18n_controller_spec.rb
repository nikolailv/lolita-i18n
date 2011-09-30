# coding: utf-8

USE_RAILS=true unless defined?(USE_RAILS)
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

include Lolita::Test::Matchers

describe Lolita::I18nController do
  render_views

  it "should have i18n routes" do
    {:get=>"/lolita/i18n"}.should be_routable
    {:put=>"/lolita/i18n/1"}.should be_routable
    {:put=>"/lolita/i18n/translate_untranslated"}.should be_routable
    {:get=>"/lolita/i18n"}.should be_routable
  end

  it "should show all translations" do
    get :index
    response.should render_template("index")
    response.body.should match(/#{::I18n.t('lolita-i18n.title')}/)
  end

  it "should save translation" do
    put :update, :id=>"en.Page title",:translation=>"New title", :format => :json
    response.body.should == {error: false}.to_json
    ::I18n.t("Page title", :locale => :en).should == "New title"
  end

  it "should translate to google" do
    stub_request(:post, "http://ajax.googleapis.com/ajax/services/language/translate").
    with(:body => "v=2.0&format=text&q=true&langpair=%7Clv&q=true&langpair=%7Clv&q=Posts&langpair=%7Clv&q=Posts%20description&langpair=%7Clv&q=Comments&langpair=%7Clv&q=Comment%20description&langpair=%7Clv&q=Footer%20text&langpair=%7Clv",
    :headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
    to_return(:status => 200, :body => '{"responseData": [{"responseData":{"translatedText":"patiess","detectedSourceLanguage":"en"},"responseDetails":null,"responseStatus":200},{"responseData":{"translatedText":"patiess","detectedSourceLanguage":"en"},"responseDetails":null,"responseStatus":200},{"responseData":{"translatedText":"Atbildes","detectedSourceLanguage":"en"},"responseDetails":null,"responseStatus":200},{"responseData":{"translatedText":"Atbildes apraksts","detectedSourceLanguage":"en"},"responseDetails":null,"responseStatus":200},{"responseData":{"translatedText":"Komentāri","detectedSourceLanguage":"en"},"responseDetails":null,"responseStatus":200},{"responseData":{"translatedText":"Cik apraksts","detectedSourceLanguage":"fr"},"responseDetails":null,"responseStatus":200},{"responseData":{"translatedText":"Kājenes tekstu","detectedSourceLanguage":"en"},"responseDetails":null,"responseStatus":200}], "responseDetails": null, "responseStatus": 200}', :headers => {})

    put :translate_untranslated, :active_locale => :lv, :format => :json
    response.body.should == {errors: [], translated: 7}.to_json
  end
end