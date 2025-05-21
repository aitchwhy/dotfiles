import {
	App,
	type AppOptions,
	type EndpointSignature,
	type RequestContext,
} from "@anterior/lib-platform/app";
import type { Logger } from "@anterior/lib-platform/log";
import type { SchemaLike } from "@anterior/lib-platform/schema";
import * as z from "@anterior/lib-platform/zod";
import type Anthropic from "@anthropic-ai/sdk";
import { parseAuthInfo } from "../auth/jwt.ts";
import type { Extracts, TextSection, PdfSection } from "./models.ts";
import { textSection, pdfSection, extractCitation } from "./models.ts";
import type { Platform } from "./platform.ts";

interface BuildS3PdfPathArgs {
	enterpriseUid: string;
	stemUid: string;
	pdfUid: string;
	filename: string;
}

function buildS3PdfPath({ enterpriseUid, stemUid, pdfUid, filename }: BuildS3PdfPathArgs): string {
	const basePath = `stems/${enterpriseUid}/${stemUid}/${pdfUid}`;
	return `${basePath}/${filename}`;
}

export interface ChatAppContext {
	logger: Logger;
	platform: Platform;
	anthropic: Anthropic;
}

type ChatRequestBody = {
	system?: string | undefined;
	messages: Array<{ role: "user" | "assistant"; content: string }>;
	stemUid: string;
	pdfUids: Array<string>;
};

// Chat API request/response schemas
export const chatRequestSchema = z.object({
	system: z.string().optional(),
	messages: z.array(
		z.object({
			role: z.enum(["user", "assistant"]),
			content: z.string(),
		})
	).min(1, "At least one message is required"),
	stemUid: z.string(),
	pdfUids: z.array(z.string()),
});
export type ChatRequest = z.infer<typeof chatRequestSchema>;

export interface ChatAppService {
	POST: {
		"/": EndpointSignature<ChatRequestBody, Response>;
	};
}

export type ChatApp = App<ChatAppService, ChatAppContext>;

export function createChatApp(ctx: ChatAppContext, options: AppOptions): ChatApp {
	ctx.logger.info({ msg: "Creating Chat App", contextKeys: Object.keys(ctx) });

	const app: ChatApp = new App(ctx, options);

	app.endpoint({
		method: "POST",
		body: z.object({
			system: z.string().optional(),
			messages: z
				.array(
					z.object({
						role: z.enum(["user", "assistant"]),
						content: z.string(),
					})
				)
				.min(1, "At least one message is required"),
			stemUid: z.string(),
			pdfUids: z.array(z.string()),
		}) satisfies SchemaLike<ChatRequestBody>,
		route: "/",
		async handler(ctx) {
			// NB: We are re-fetching the extracts for each chat message from S3
			// This can slow the request a bit, profile before you optimize
			const extractsByPdfUid = await getExtractsByPdfUid(ctx);
			
			// Create a structured prompt with the PDF extracts
			const structuredPrompt = buildStructuredPrompt(ctx.body.messages[ctx.body.messages.length - 1].content, extractsByPdfUid);

			// Call Claude directly with the structured prompt
			const response = await callClaudeWithPrompt(structuredPrompt, ctx.anthropic);
			
			// Parse the response for citations
			const parsedResponse = parseResponseWithCitations(response, extractsByPdfUid, ctx.logger);

			// Return a standard REST API response
			return new Response(parsedResponse, {
				headers: {
					"Content-Type": "application/json",
					"Cache-Control": "no-cache",
				},
			});
		},
	});

	return app;
}

// Helper function to build the structured prompt with PDF extracts
function buildStructuredPrompt(userQuestion: string, extractsByPdfUid: Record<string, Extracts>): string {
	// Start with the base prompt template
	let prompt = `You are an expert research assistant tasked with answering questions based on provided PDF document extracts. Your goal is to find relevant information within these documents and provide a well-cited answer to the given question.

Here are the PDF documents that you will be referencing, formatted in XML and broken down into extracts referenced by extract ID:

<pdfs>`;

	// Add each PDF extract
	Object.entries(extractsByPdfUid).forEach(([pdfUid, extracts], pdfIndex) => {
		prompt += `\n<pdf${pdfIndex + 1}>`;
		extracts.extracts.forEach((extract, extractIndex) => {
			const extractId = `${pdfUid}.extract_${extractIndex}`;
			prompt += `\n<extract ids="${extractId}">${extract.text}</extract>`;
		});
		prompt += `\n</pdf${pdfIndex + 1}>`;
	});

	// Close PDFs section and add the question
	prompt += `\n</pdfs>\n\nThe question you need to answer is:\n<question>\n${userQuestion}\n</question>\n\n`;

	// Add instructions for formatting the response
	prompt += `To complete this task, follow these steps:
1. Carefully review the PDF documents and identify quotes that are most relevant to answering the question. These quotes should be relatively short and provide valid backing for your answer.
2. List the relevant quotes in numbered order. If there are no relevant quotes, write "No relevant quotes" instead.
3. Formulate your answer to the question, starting with "Answer:". Do not include or reference quoted content verbatim in your answer.
4. When citing information in your answer, use the following format:
   <extract ids="pdf_id.ext_id.block_id">Cited text goes here.</extract>
   Replace "pdf_id.ext_id.block_id" with the actual identifiers for the extract where the cited text is located.

Remember to use the provided PDF documents as your sole source of information. Do not include any external knowledge or assumptions in your answer. If the question cannot be fully answered using the available information, state this clearly in your response.\n\nNow, please proceed with answering the question based on the provided PDF documents.`;

	return prompt;
}

// Helper function to call Claude directly
async function callClaudeWithPrompt(prompt: string, anthropic: any): Promise<string> {
	try {
		const response = await anthropic.messages.create({
			model: "claude-3-sonnet-20240229", // Adjust based on your available models
			max_tokens: 4000,
			temperature: 0.3,
			messages: [{ role: "user", content: prompt }],
		});

		return response.content[0].text;
	} catch (error) {
		throw error;
	}
}

// Helper function to parse the response and extract citations
function parseResponseWithCitations(response: string, extractsByPdfUid: Record<string, Extracts>, logger: any): string {
	try {
		// Check if the response contains the <extract> tag
		if (!response.includes('<extract')) {
			// If there are no citations, return the response as is
			return JSON.stringify({ content: [{ type: "text", text: response }] });
		}

		// Parse the response to extract citation sections
		const sections: TextSection[] = [];
		let remaining = response;

		// Simple XML parsing loop to extract citations
		while (remaining.length > 0) {
			const extractStart = remaining.indexOf('<extract');
			if (extractStart === -1) {
				// No more extracts, add the remaining text as a section without citations
				if (remaining.trim().length > 0) {
					sections.push({
						text: remaining,
						section_type: "text_section_v01_20250514",
						start: 0,
						end: remaining.length,
					});
				}
				break;
			}

			// Add the text before the extract
			const textBeforeExtract = remaining.substring(0, extractStart);
			if (textBeforeExtract.trim().length > 0) {
				sections.push({
					text: textBeforeExtract,
					section_type: "text_section_v01_20250514",
					start: 0,
					end: textBeforeExtract.length,
				});
			}

			// Extract the ids attribute
			const idsMatch = remaining.substring(extractStart).match(/ids="([^"]*)"/i);
			const ids = idsMatch ? idsMatch[1].split(',') : [];

			// Move ahead to extract closing tag
			const tagContentStart = remaining.indexOf('>', extractStart) + 1;
			if (tagContentStart === 0) {
				// Malformed XML, add the remaining text as a section
				sections.push({
					text: remaining,
					section_type: "text_section_v01_20250514",
					start: 0,
					end: remaining.length,
				});
				break;
			}

			// Find the extract closing tag
			const extractEnd = remaining.indexOf('</extract>', tagContentStart);
			if (extractEnd === -1) {
				// Malformed XML, add the remaining text as a section
				sections.push({
					text: remaining,
					section_type: "text_section_v01_20250514",
					start: 0,
					end: remaining.length,
				});
				break;
			}

			// Extract the citation text
			const citedText = remaining.substring(tagContentStart, extractEnd);

			// Process each ID to create citations
			const citations = ids.map(id => {
				const [pdfId, extractId, blockId] = id.split('.');

				// Create a PDF section for the citation if possible
				let pdfSectionObj: PdfSection | undefined;

				// In a real implementation, you would look up the actual page and bounding box
				// For now, use default values
				pdfSectionObj = {
					section_type: "pdf_section_v01_20250514",
					page: 1, // Default to page 1
					bounding_box: {
						top: 0.2,
						right: 0.8,
						bottom: 0.3,
						left: 0.2,
					}
				};

				return {
					pdf_id: pdfId,
					extract_id: extractId,
					cited_text: citedText,
					start_char: 0,
					end_char: citedText.length,
					pdf_section: pdfSectionObj
				};
			});

			// Add the extract as a text section with citation
			sections.push({
				text: citedText,
				section_type: "text_section_v01_20250514",
				start: 0,
				end: citedText.length,
				citations: citations
			});

			// Continue processing with the remaining text
			remaining = remaining.substring(extractEnd + '</extract>'.length);
		}

		// Format the final response
		const formattedResponse = {
			content: [
				{
					type: "text_with_citations",
					text: response.replace(/<extract[^>]*>|<\/extract>/g, ''),
					sections
				}
			]
		};

		return JSON.stringify(formattedResponse);
	} catch (error) {
		logger.error({ msg: "Error parsing citations", error });
		// Return the original response as fallback
		return JSON.stringify({ content: [{ type: "text", text: response }] });
	}
}

async function getExtractsByPdfUid(
	ctx: RequestContext<ChatAppContext, "/", {}, unknown, unknown, ChatRequestBody>
) {
	const { enterpriseUid } = parseAuthInfo(ctx);
	const { stemUid, pdfUids } = ctx.body;
	const s3Keys = pdfUids.map((pdfUid) => {
		return {
			s3Key: buildS3PdfPath({
				enterpriseUid,
				stemUid,
				pdfUid,
				filename: "extracts.json",
			}),
			pdfUid,
		};
	});

	const blobs = await Promise.all(
		s3Keys.map(async ({ s3Key, pdfUid }) => ({
			blob: await ctx.platform.blobs.fetchBlob(s3Key),
			pdfUid,
		}))
	);
	const texts = await Promise.all(
		blobs.map(async ({ blob, pdfUid }) => ({ text: await blob.text(), pdfUid }))
	);
	const extractsRaw = texts.map(({ text, pdfUid }) => ({
		extractsRaw: JSON.parse(text),
		pdfUid,
	}));
	return extractsRaw.reduce(
		(acc, curr) => {
			acc[curr.pdfUid] = curr.extractsRaw;
			return acc;
		},
		{} as Record<string, Extracts>
	);
}
