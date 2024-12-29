# frozen_string_literal: true

RSpec.describe Regent::LLM do

  subject { Regent::LLM.new(model) }

  context "Unsupported model" do
    let(:model) { "llama-3.1-8b" }

    it "raises an error if the model is not supported" do
      expect { subject }.to raise_error(Regent::LLM::ProviderNotFoundError)
    end
  end

  context "API key not set in environment" do
    let(:model) { "gpt-4o-mini" }

    it "raises an error if the API key is not set" do
      original_api_key = ENV["OPENAI_API_KEY"]
      ENV["OPENAI_API_KEY"] = nil
      expect { subject }.to raise_error(Regent::LLM::APIKeyNotFoundError)
    ensure
      ENV["OPENAI_API_KEY"] = original_api_key
    end
  end

  context "Missing model dependency" do
    let(:model) { "claude-3-5-sonnet-20240620" }

    before do
      allow_any_instance_of(Regent::LLM).to receive(:gem).with("anthropic").and_raise(Gem::LoadError)
    end

    it "warns and exists if the dependency is not installed" do
      expect { subject }.to output(
        "\n\e[33mIn order to use \e[33;1mclaude-3-5-sonnet-20240620\e[0m\e[33m model you need to install \e[33;1manthropic\e[0m\e[33m gem. Please add \e[33;1mgem \"anthropic\"\e[0m\e[33m to your Gemfile.\e[0m"
      ).to_stdout.and(exit)
    end
  end
end
