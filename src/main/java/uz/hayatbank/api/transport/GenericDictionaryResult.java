package uz.hayatbank.api.transport;

import lombok.Data;
import lombok.EqualsAndHashCode;

import java.util.List;

@EqualsAndHashCode(callSuper = true)
@Data
public class GenericDictionaryResult extends GenericResult {
    private List<?> dictionary;
}
