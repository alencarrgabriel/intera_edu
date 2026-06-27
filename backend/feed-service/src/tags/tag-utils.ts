/// Extracts unique hashtags from text content.
/// Returns lowercase slugs without the leading '#'.
/// Accepts Unicode letters/digits and underscores. Min length 2, max 32.
export function extractHashtags(content: string): string[] {
  if (!content) return [];
  const re = /#([\p{L}\p{N}_]{2,32})/gu;
  const matches = content.matchAll(re);
  const slugs = new Set<string>();
  for (const m of matches) {
    slugs.add(m[1].toLowerCase());
  }
  return [...slugs];
}

/// Extracts mention handles (@usuario).
export function extractMentions(content: string): string[] {
  if (!content) return [];
  const re = /@([\p{L}\p{N}_.]{3,32})/gu;
  const matches = content.matchAll(re);
  const handles = new Set<string>();
  for (const m of matches) {
    handles.add(m[1].toLowerCase());
  }
  return [...handles];
}
