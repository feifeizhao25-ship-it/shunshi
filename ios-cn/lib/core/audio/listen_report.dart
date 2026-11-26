/// 没有音频条目时不要上报。空的 audio_id 会被接口拒绝（422），也不是一条收听记录。
bool reportsListenProgress(String? audioId) => (audioId ?? '').trim().isNotEmpty;
