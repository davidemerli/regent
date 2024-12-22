# frozen_string_literal: true

RSpec.describe Regent::Agent, :vcr do
  let(:llm) { Langchain::LLM::OpenAI.new(api_key: ENV['OPENAI_API_KEY']) }
  let(:agent) { Regent::Agent.new(llm: llm) }


  context "without a tool" do
    let(:cassette) { "Regent_Agent/answers_a_basic_question" }

    it "answers a basic question" do
      expect(agent.execute("What is the capital of Japan?")).to eq("The capital of Japan is Tokyo.")
    end

    it "stores messages within a session" do
      agent.execute("What is the capital of Japan?")

      expect(agent.session.messages).to eq([
        { role: :system, content: Regent::Arch::React::SYSTEM_PROMPT.gsub("%{tools}", "") },
        { role: :user, content: "What is the capital of Japan?" },
        { role: :assistant, content: "Thought: I need to find out what the capital of Japan is. \nAction: I will recall my knowledge about countries and their capitals. \nObservation: The capital of Japan is Tokyo. \n\nThought: I have the answer now.\nAnswer: The capital of Japan is Tokyo." }
      ])
    end

    it "stores session history" do
      agent.execute("What is the capital of Japan?")

      expect(agent.session.spans.count).to eq(3)
      expect(agent.session.spans.first.type).to eq(Regent::Span::Type::INPUT)
      expect(agent.session.spans.first.output).to eq("What is the capital of Japan?")
      expect(agent.session.spans[1].type).to eq(Regent::Span::Type::LLM_CALL)
      expect(agent.session.spans[1].output).to eq("Thought: I need to find out what the capital of Japan is. \nAction: I will recall my knowledge about countries and their capitals. \nObservation: The capital of Japan is Tokyo. \n\nThought: I have the answer now.\nAnswer: The capital of Japan is Tokyo.")

      expect(agent.session.spans.last.type).to eq(Regent::Span::Type::ANSWER)
      expect(agent.session.spans.last.output).to eq("The capital of Japan is Tokyo.")
    end
  end

  context "with a tool" do
    let(:cassette) { "Regent_Agent/answers_a_question_with_a_tool" }

    class PriceTool < Regent::Tool
      def call(query)
        "{'BTC': '$107,000', 'ETH': '$6,000'}"
      end
    end

    let(:agent) { Regent::Agent.new(llm: llm, tools: [PriceTool.new(name: 'price_tool', description: 'Get the price of cryptocurrencies')]) }

    it "answers a question with a tool" do
      expect(agent.execute("What is the price of Bitcoin?")).to eq("The price of Bitcoin is $107,000.")
      expect(agent.execute("What is the price of Ethereum?")).to eq("The price of Ethereum is $6,000.")
    end

    it "stores messages within a session" do
      agent.execute("What is the price of Bitcoin?")

      expect(agent.session.messages).to eq([
        { role: :system, content: Regent::Arch::React::SYSTEM_PROMPT.gsub("%{tools}", "price_tool - Get the price of cryptocurrencies") },
        { role: :user, content: "What is the price of Bitcoin?" },
        { role: :assistant, content: "Thought: I need to find the current price of Bitcoin. \nAction: price_tool | \"Bitcoin\"\nPAUSE" },
        { role: :user, content: "Observation: {'BTC': '$107,000', 'ETH': '$6,000'}" },
        { role: :assistant, content: "Thought: I have the current price of Bitcoin, which is $107,000. \nAnswer: The price of Bitcoin is $107,000." }
      ])
    end

    it "stores session history" do
      agent.execute("What is the price of Bitcoin?")

      expect(agent.session.spans.count).to eq(5)
      expect(agent.session.spans.first.type).to eq(Regent::Span::Type::INPUT)
      expect(agent.session.spans[1].type).to eq(Regent::Span::Type::LLM_CALL)
      expect(agent.session.spans[2].type).to eq(Regent::Span::Type::TOOL_EXECUTION)
      expect(agent.session.spans[3].type).to eq(Regent::Span::Type::LLM_CALL)
      expect(agent.session.spans.last.type).to eq(Regent::Span::Type::ANSWER)
    end
  end
end
