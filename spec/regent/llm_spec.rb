# frozen_string_literal: true

RSpec.describe Regent::LLM do
  let(:strict_mode) { true }
  let(:messages) { [{ role: :user, content: "What is the capital of Japan?" }] }

  subject { Regent::LLM.new(model, strict_mode: strict_mode) }

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

  context "API error", vcr: true do
    context "OpenAI" do
      let(:model) { "gpt-4.1o-mini" }
      let(:cassette) { "LLM/OpenAI/non_existent_model" }

      context "strict mode" do
        it "raises an API error" do
          expect { subject.invoke(messages) }.to raise_error(
            Regent::LLM::ApiError,
            "The model `gpt-4.1o-mini` does not exist or you do not have access to it."
          )
        end
      end

      context "non strict mode" do
        let(:strict_mode) { false }

        it "returns a result with error message" do
          result = subject.invoke(messages)
          expect(result).to be_a(Regent::LLM::Result)
          expect(result.content).to eq("The model `gpt-4.1o-mini` does not exist or you do not have access to it.")
        end
      end
    end

    context "Gemini" do
      let(:model) { "gemini-3.5-flash" }
      let(:cassette) { "LLM/Google_Gemini/non_existent_model" }

      context "strict mode" do
        it "raises an API error" do
          expect { subject.invoke(messages) }.to raise_error(
            Regent::LLM::ApiError,
            "models/gemini-3.5-flash is not found for API version v1, or is not supported for generateContent. Call ListModels to see the list of available models and their supported methods."
          )
        end
      end

      context "non strict mode" do
        let(:strict_mode) { false }

        it "returns a result with error message" do
          result = subject.invoke(messages)
          expect(result).to be_a(Regent::LLM::Result)
          expect(result.content).to eq("models/gemini-3.5-flash is not found for API version v1, or is not supported for generateContent. Call ListModels to see the list of available models and their supported methods.")
        end
      end
    end

    context "Anthropic" do
      let(:model) { "claude-4.1-haiku" }
      let(:cassette) { "LLM/Anthropic/non_existent_model" }

      context "strict mode" do
        it "raises an API error" do
          expect { subject.invoke(messages) }.to raise_error(
            Regent::LLM::ApiError,
            "system: Input should be a valid list"
          )
        end
      end

      context "non strict mode" do
        let(:strict_mode) { false }

        it "returns a result with error message" do
          result = subject.invoke(messages)
          expect(result).to be_a(Regent::LLM::Result)
          expect(result.content).to eq("system: Input should be a valid list")
        end
      end
    end
  end

  context "Missing model dependency" do
    let(:model) { "claude-3-5-sonnet-20240620" }
    let(:instance) { double(Regent::LLM::Base, warn_and_exit: nil) }

    before do
      allow(Regent::LLM::Base).to receive(:new).and_return(instance)
      allow_any_instance_of(Regent::LLM::Base).to receive(:gem).with("anthropic").and_raise(Gem::LoadError)
    end

    xit "warns and exists if the dependency is not installed" do
      subject

      expect(instance).to have_received(:warn_and_exit).with("anthropic", "claude-3-5-sonnet-20240620")
    end
  end
end
