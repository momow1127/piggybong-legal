import "https://deno.land/x/xhr@0.1.0/mod.ts";
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
};

const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY');

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    if (!anthropicApiKey) {
      throw new Error('Anthropic API key not configured');
    }

    const {
      prompt,
      type = 'component',
      framework = 'react',
      style = 'tailwind',
      includeTypes = true,
      complexity = 'medium'
    } = await req.json();

    console.log('Generating code for:', {
      prompt,
      type,
      framework,
      style
    });

    const systemPrompt = `You are an expert full-stack developer specializing in modern web development. Generate clean, production-ready code based on the user's requirements.

REQUIREMENTS:
- Framework: ${framework} with TypeScript
- Styling: ${style === 'tailwind' ? 'Tailwind CSS with semantic design tokens' : style}
- Type: ${type}
- Complexity: ${complexity}
- Include TypeScript types: ${includeTypes}

GUIDELINES:
1. Use modern React patterns (hooks, functional components)
2. Follow best practices for accessibility and performance
3. Use semantic HTML elements
4. Implement proper TypeScript typing
5. Use Tailwind CSS design system tokens (hsl(var(--primary)), etc.)
6. Include proper error handling
7. Add helpful comments
8. Make code mobile-responsive
9. Follow React component composition patterns
10. Use proper imports and exports

RESPONSE FORMAT:
Return only valid JSON with these fields:
- code: The complete code file content
- filename: Suggested filename with extension
- description: Brief description of what the code does
- dependencies: Array of required npm packages
- usage_example: Example of how to use the component/function
- tests: Basic test example (optional)

Do not include markdown formatting or code blocks in the JSON response.`;

    const userPrompt = `Generate a ${type} with the following requirements:

${prompt}

Additional context:
- This is for a modern React application with Supabase backend
- Use TypeScript for type safety
- Follow mobile-first responsive design principles
- Include proper error handling and loading states
- Use modern React patterns (hooks, context when needed)
- Implement accessibility features (ARIA labels, keyboard navigation)
- Use Tailwind CSS design system tokens for consistent styling`;

    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${anthropicApiKey}`,
        'Content-Type': 'application/json',
        'x-api-version': '2023-06-01'
      },
      body: JSON.stringify({
        model: 'claude-3-5-sonnet-20241022',
        max_tokens: 3000,
        temperature: 0.3,
        messages: [
          {
            role: 'user',
            content: `${systemPrompt}\n\n${userPrompt}`
          }
        ]
      })
    });

    if (!response.ok) {
      console.error('Anthropic API error:', response.status, await response.text());
      throw new Error(`Anthropic API error: ${response.status}`);
    }

    const data = await response.json();
    const generatedContent = data.content[0].text;

    console.log('Generated content length:', generatedContent.length);

    // Parse the JSON response
    let parsedResponse;
    try {
      parsedResponse = JSON.parse(generatedContent);
    } catch (parseError) {
      console.error('Failed to parse AI response as JSON:', parseError);
      // Fallback: try to extract code from markdown if AI didn't follow format
      const codeMatch = generatedContent.match(/```(?:tsx?|jsx?|typescript|javascript)?\n([\s\S]*?)\n```/);
      const extractedCode = codeMatch ? codeMatch[1] : generatedContent;

      parsedResponse = {
        code: extractedCode,
        filename: `generated-${type}.tsx`,
        description: `Generated ${type} based on: ${prompt}`,
        dependencies: [],
        usage_example: `// Import and use the generated ${type}`
      };
    }

    // Validate the response
    if (!parsedResponse.code || !parsedResponse.filename) {
      throw new Error('Invalid response from AI: missing required fields');
    }

    console.log('Successfully generated code:', parsedResponse.filename);

    return new Response(
      JSON.stringify(parsedResponse),
      {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        }
      }
    );

  } catch (error) {
    console.error('Error in generate-code function:', error);

    return new Response(
      JSON.stringify({
        error: 'Failed to generate code',
        details: error.message,
        code: '// Error generating code',
        filename: 'error.tsx',
        description: 'Code generation failed'
      }),
      {
        status: 500,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        }
      }
    );
  }
});