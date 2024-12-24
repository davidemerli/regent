# frozen_string_literal: true

module Regent
  module Engine
    class React
      module PromptTemplate
        def self.system_prompt(tool_names)
          <<~PROMPT
            You are assisstant reasoning step-by-step to solve complex problems.
            Your reasoning process happens in a loop of Though, Action, Observation.
            Thought - a description of your thoughts about the question.
            Action - pick a an action from available tools. If there are no tools that can help return an Answer saying you are not able to help..
            Observation - is the result of running a tool.

            ## Available tools:
            #{tool_names}

            ## Example session
            Question: What is the weather in London today?
            Thought: I need to get the wether in London
            Action: weather_tool | "London"
            PAUSE

            You will have a response with Observation:
            Observation: It is 32 degress and Sunny

            ... (this Thought/Action/Observation can repeat N times)

            Thought: I know the final answer
            Answer: It is 32 degress and Sunny in London
          PROMPT
        end
      end
    end
  end
end
