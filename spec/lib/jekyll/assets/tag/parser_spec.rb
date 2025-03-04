require "rspec/helper"
describe Jekyll::Assets::Tag::Parser do
  let(:escape_error) { Jekyll::Assets::Tag::Parser::UnescapedColonError }
  let( :proxy_error) { Jekyll::Assets::Tag::Parser::UnknownProxyError }
  let(       :klass) { described_class }
  before :each, :proxies => true do
    allow(Jekyll::Assets::Tag::Proxies).to receive(:all).and_return(Set.new([{
      :cls=> :internal,
      :args=>[
        "resize",
        "@2x"
      ],

      :name=>[
        :magick,
        "magick"
      ],

      :tags=>[
        :img,
        "img"
      ],
    }]))
  end

  it "properly parses syntax", :proxies => true do
    input = "hello.jpg lol key:value magick:2x magick:resize:2x2"
    expect(klass.new(input, "img").args).to match({
      :file=>"hello.jpg",
      :magick => {
        :resize => "2x2",
        :"2x" => true
      },

      :html => {
        "lol"=>true,
        "key"=>"value"
      }
    })
  end

  it "raises an error if there is no proxy available" do
    input = "img.jpg sprockets:unknown:hello"
    expect { klass.new(input, "img") }.to raise_error \
      Jekyll::Assets::Tag::Parser::UnknownProxyError
  end

  it "makes like 'proxy' argument an HTML argument if there is no proxy key" do
    input = "img.jpg sprockets:unknown"
    expect(klass.new(input, "img").args[:html]["sprockets"]).to eq \
      "unknown"
  end

  it "allows boolean proxy arguments", :proxies => true do
    expect(klass.new("img.jpg magick:2x", "img").args[:magick][:"2x"]).to eq \
      true
  end

  it "does not allocate boolean arguments as proxy values", :proxies => true do
    expect { klass.new("img.jpg magick:2x:raise", "img") }.to raise_error \
      proxy_error
  end

  it "expects escaping more than one colon with quotes" do
    input = "hello.jpg sprockets:accept:'image:gif'"
    expect { klass.new(input, "img") }.to raise_error \
      escape_error
  end

  it "expects escaping more than one colon without quotes" do
    input = "hello.jpg sprockets:acpet:image:gif"
    expect { klass.new(input, "img") }.to raise_error \
      escape_error
  end

  it "allows escaping inside of quotes" do
    input = 'hello.jpg sprockets:accept:"image\\\:gif"'
    expect(klass.new(input, "img")[:sprockets][:accept]).to eq \
      "image:gif"
  end

  it "allows quoting the entire argument" do
    input = "hello.jpg 'sprockets:accept:image/gif'"
    expect(klass.new(input, "img").args[:sprockets][:accept]).to eq \
      "image/gif"
  end

  it "allows quoting only fragments of an argument" do
    input = "hello.jpg sprockets:accept:'image/gif'"
    expect(klass.new(input, "img").args[:sprockets][:accept]).to eq \
      "image/gif"
  end
end
